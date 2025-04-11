public class Demo3 {

  // PMD Violation: Method names should be in camelCase
  public void mainvaluemethod()
  {
    // PMD Violation: 'string' should be 'String'
    string websiteURL = 'www.apexhours.com';
    
    // PMD Violation: 'system' should be 'System'
    system.debug('before passbyvalue:' + websiteURL);
    
    passbyvaluecall(websiteURL);
    
    system.debug('after passbyvalue:' + websiteURL);
   }

   // PMD Violation: Method name not in camelCase, and type capitalization
   public void passbyvaluecall(string websiteURLvalue)
   {
       // PMD Violation: Unused assignment
       websiteURLvalue = 'www.salesforce.com';
   }
}