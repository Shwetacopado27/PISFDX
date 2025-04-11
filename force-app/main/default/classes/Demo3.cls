public class Demo3 {

  // PMD Violation: Unused private method
  private void unusedHelper() {
    Integer a = 5;
  }

  public void mainValueMethod() {
    String websiteURL = 'www.apexhours.com';

    try {
      Integer x = 10 / 0;
    } catch (Exception e) {
      // PMD Violation: Empty catch block
    }

    // PMD Violation: Empty if statement
    if (websiteURL == 'www.apexhours.com') {
    }

    // PMD Violation: Hardcoded ID
    Id someRecord = '001ABC000000XYZ';

    // PMD Violation: Deep nesting
    if (true) {
      if (true) {
        if (true) {
          if (true) {
            System.debug('Very deeply nested!');
          }
        }
      }
    }

    passByValueCall(websiteURL);
  }

  public void passByValueCall(String websiteURLValue) {
    websiteURLValue = 'www.salesforce.com';
  }
}