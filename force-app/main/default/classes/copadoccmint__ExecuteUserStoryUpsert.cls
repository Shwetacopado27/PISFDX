/**
 * Upserts an External User Story into Copado's User Story.
 *
 * @author Ümit Can Uçkan
 * @lastModifiedBy Kunal Kaushik
 * @version 2.0
 * @since CCM Integrations 1.0
 */
global class ExecuteUserStoryUpsert extends JiraIntegrationConstants implements Database.Batchable<Object>, Database.AllowsCallouts {
    private String salesforceAssigneeApiName;
    private Map<String, Id> userIdsByUserEmails = new Map<String, Id>();
    private Map<String, Id> userIdsByUserFullName = new Map<String, Id>();
    private Map<String, String> userFullNameByUserEmails = new Map<String, String>();
    private Map<String, List<copado__User_Story__c>> userStoriesByAssignee = new Map<String, List<copado__User_Story__c>>();
    global copado__Project__c gProject;
    private Boolean isSprint;
    List<copado__User_Story__c> userStories2Upsert;
    private List<Map<String, String>> userStoryList;
    //Field mapping values between salesforce and third party platform fields under related project
    global Map<String, String> fieldMap {
        get {
            if (null == fieldMap) {
                fieldMap = CopadoCCMutilities.returnFieldMap(gProject.Id, DONT_EXCLUDE_FROM_SALESFORCE);
            }
            return fieldMap;
        }
        set;
    }
    //Record Type mapping values between salesforce and third party platform Work Items under related project
    global Map<String, String> recordTypeMap {
        get {
            if (null == recordTypeMap) {
                recordTypeMap = CopadoCCMutilities.returnRecordTypeMap(gProject.Id, false);
            }
            return recordTypeMap;
        }
        set;
    }
    
    //Theme object records Name=>Id Map
    global Map<String, Id> themeMap {
        get {
            if (null == themeMap) {
                themeMap = CopadoCCMutilities.returnThemeMap();
            }
            return themeMap;
        }
        set;
    }

    //Theme mapping object records tp Name=>sf Name Map
    global Map<String, String> themeMapping {
        get {
            if (null == themeMapping) {
                themeMapping = CopadoCCMutilities.returnThemeMappingForProject(gProject.Id);
            }
            return themeMapping;
        }
        set;
    }
    
    //Team object records Name=>Id Map
    global Map<String, Id> teamMap {
        get {
            if (null == teamMap) {
                teamMap = CopadoCCMutilities.returnTeamMap();
            }
            return teamMap;
        }
        set;
    }
    
    //User Story object record Type name=>Id Map
    global Map<String, String> userStoryRecordTypeMap {
        get {
            if (null == userStoryRecordTypeMap) {
                Boolean forJIRA = false;
                userStoryRecordTypeMap = CopadoCCMutilities.returnUserStoryRecordTypeMap(forJIRA);
            }
            return userStoryRecordTypeMap;
        }
        set;
    }
    //constructor to have the project via schedule class
    global ExecuteUserStoryUpsert(copado__Project__c proParam, Boolean isSprint) {
        gProject = proParam;
        this.isSprint = isSprint;
        userStoryList = new List<Map<String, String>>();
    }
    //constructor to have the project via schedule class with User Story records
    global ExecuteUserStoryUpsert(copado__Project__c proParam, List<Map<String, String>> userStoryListParam) {
        gProject = proParam;
        this.isSprint = true;
        userStoryList = userStoryListParam;
    }
    global ExecuteUserStoryUpsert(copado__Project__c proParam, List<Map<String, String>> userStoryListParam, Boolean isSprint) {
        gProject = proParam;
        this.isSprint = isSprint;
        userStoryList = userStoryListParam;
    }
    //Finds related instance based on external system to use via factory pattern, fetches and parses the JSON and return to execute method
    global Iterable<Object> start(Database.BatchableContext BC) {
        if (null != userStoryList && !userStoryList.isEmpty()) {
            return new CallIterable(userStoryList);
        } else {
            return new CallIterable(
                IntegrationFactory.returnInstance(gProject.Copado_Integration_Setting__r.External_System__c).fetchRecords(gProject, isSprint , true)
            );
        }
    }
    global void execute(Database.BatchableContext BC, List<Object> scope) {
        userStories2Upsert = new List<copado__User_Story__c>();
        //loops among user story Items Map
        for (Object usItem : scope) {
            Map<String, String> tempMap = (Map<String, String>) usItem;
            sObject sobj = new copado__User_Story__c();
            if (!tempMap.containsKey(ASSIGNEE) && !tempMap.containsKey(DEVELOPER_KEYWORD)){
                tempMap.put(ASSIGNEE,null);
            }
            
            //loops among field Mapping items under related project
            for (String fieldName : fieldMap.keyset()) {
                fieldName = fieldName.toLowerCase();
                //puts the value on sf Object if the current user story item value Map stores current field Map keyset
                String thirdPartyApiName = fieldMap.get(fieldName);
                if (tempMap.containsKey(thirdPartyApiName)) {
                    if (fieldName == COPADO_RELEASE) {
                        if(CopadoCCMutilities.returnCastedValue(tempMap.get(fieldMap.get(fieldName)), fieldName) != null){
                            Sobject releaseObj = Schema.getGlobalDescribe().get(fieldName).newSObject();
                            releaseObj.put(EXTERNAL_ID, CopadoCCMutilities.returnCastedValue(tempMap.get(fieldMap.get(fieldName)), fieldName));
                            sobj.putsObject(copado__User_Story__c.copado__Release__c.getDescribe().getSObjectField(), releaseObj);
                        } else {
                            sobj.put(copado__User_Story__c.copado__Release__c.getDescribe().getSObjectField(), null);
                        }  
                    } else if (fieldName == RECORD_TYPE_ID && !recordTypeMap.isEmpty()) {
                        String thirdPartyType = tempMap.get(fieldMap.get(fieldName));
                        String sfType = recordTypeMap.get(thirdPartyType);
                        if (null != sfType) {
                            Id sfTypeId = UserStoryRecordTypeMap.get(sfType);
                            sobj.put(fieldName, sfTypeId);
                        }
                    } else if (thirdPartyApiName == THEME_KEYWORD) {
                        String lowercaseName = tempMap.get(thirdPartyApiName).toLowercase();
                        for(String splitted : lowercaseName.split(';')){
                            if(null != themeMapping.get(splitted) && themeMap.containsKey(themeMapping.get(splitted)) || themeMap.containsKey(splitted)){
                                String fieldValue = themeMap.containsKey(splitted) ? themeMap.get(splitted) : themeMap.get(themeMapping.get(splitted));
                                sobj.put(fieldName, fieldValue); 
                                //break is implemented to finish the iteration when we catch a match
                                break;
                            }
                        }
                    } else if (thirdPartyApiName == TEAM_WORD) {
                        String lowercaseName = tempMap.get(thirdPartyApiName).toLowercase();
                        if(teamMap.containsKey(lowercaseName)){
                            sobj.put(fieldName, teamMap.get(lowercaseName)); 
                        }
                    } else if (thirdPartyApiName == ASSIGNEE || thirdPartyApiName == DEVELOPER_KEYWORD) {
                        salesforceAssigneeApiName = fieldName;
                        String emailValue = tempMap.get(thirdPartyApiName), nameValue;
                        if(tempMap.containsKey(thirdPartyApiName+'__dname')){
                            nameValue = tempMap.get(thirdPartyApiName+'__dname');
                        }
                        List<copado__User_Story__c> userStories = new List<copado__User_Story__c>();
                        if(userStoriesByAssignee.containsKey(emailValue)){
                            userStories = userStoriesByAssignee.get(emailValue);
                        }
                        userStories.add((copado__User_Story__c) sobj);
                        userIdsByUserEmails.put(emailValue, null);
                        userIdsByUserFullName.put(nameValue, null);
                        userStoriesByAssignee.put(emailValue, userStories);
                        userFullNameByUserEmails.put(emailValue, nameValue);
                    } else {
                        sobj.put(fieldName, CopadoCCMutilities.returnCastedValue(tempMap.get(fieldMap.get(fieldName)), fieldName));
                    }
                }
            }
        }

        List <AggregateResult> usersWithCommonEmail = [SELECT Count(Id), Email FROM User WHERE Email IN : userIdsByUserEmails.keySet() Group By Email Having Count(Id) > 1];
        Set <String> duplicateEmailSet = new Set<String>();

        if(usersWithCommonEmail.size() > 0){
            for(AggregateResult user : usersWithCommonEmail){
                duplicateEmailSet.add((String)user.get('Email'));
            }
            for(String email : duplicateEmailSet){
                List<copado__User_Story__c> userStories = userStoriesByAssignee.containsKey('null') ? userStoriesByAssignee.get('null') : new List<copado__User_Story__c>();
                for(copado__User_Story__c userStory : userStoriesByAssignee.get(email)){
                   userStories.add(userStory);
                }
                userStoriesByAssignee.put('null',userStories);
                userStoriesByAssignee.remove(email);
            }
        }
        for(User userItem : [SELECT Id, Name, Email FROM User WHERE Email IN : userIdsByUserEmails.keySet() OR NAME IN : userIdsByUserFullName.keyset()]){
            if(userIdsByUserEmails.containsKey(userItem.Email)){
                userIdsByUserEmails.put(userItem.Email, userItem.Id);
            } else {
                userIdsByUserFullName.put(userItem.Name, userItem.Id);
            }
        }
        for(String email : userStoriesByAssignee.keySet()){
            for(copado__User_Story__c userStory : userStoriesByAssignee.get(email)){
                String fullName = userFullNameByUserEmails.get(email);
                if(userIdsByUserEmails.containsKey(email) && userIdsByUserEmails.get(email) !=null){
                    userStory.put(salesforceAssigneeApiName, userIdsByUserEmails.get(email));
                } else if(userIdsByUserFullName.containsKey(fullName) && userIdsByUserFullName.get(fullName) !=null){
                    userStory.put(salesforceAssigneeApiName, userIdsByUserFullName.get(fullName));
                }
                userStories2Upsert.add(userStory);
            }
        }
        try {
            //performs upsert based on third party id
            upsert userStories2Upsert External_Id__c;
            try{
                if(usersWithCommonEmail.size() > 0){
                    throw new ApplicationException(Label.MultipleUsersWithCommonEmail);
                }
            }
            catch(ApplicationException ex){
                System.debug('Exception : ' + ex.getMessage());
            }
            
        } catch (DmlException ex) {
            System.debug('ExecuteUserStoryUpsert dml exception==> ' + ex.getMessage());
        }
    }
    global void finish(Database.BatchableContext BC) {
    }
    public class ApplicationException extends Exception {}
}