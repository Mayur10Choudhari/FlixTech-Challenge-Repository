@isTest
private class AccountContractControllerTest {
    @testSetup
    static void setupTestData() {
        // Query a valid picklist value dynamically
        Schema.DescribeFieldResult fieldResult = Account_Contract_Clause__c.Billing_Country__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        String validCountry = picklistValues.isEmpty() ? 'DefaultValue' : picklistValues[0].getValue();
        
        // Create test account
        Account testAccount = new Account(Name = 'Test Account', BillingCountry = validCountry);
        insert testAccount;
        
        // Create test clauses
        List<Account_Contract_Clause__c> clauses = new List<Account_Contract_Clause__c>();
        for (Integer i = 0; i < 3; i++) {
            clauses.add(new Account_Contract_Clause__c(Name = 'Clause ' + i, Billing_Country__c = validCountry));
        }
        insert clauses;
    }

    @isTest
    static void testGetAccountClauses() {
        Test.startTest();
        List<Account_Contract_Clause__c> result = AccountContractController.getAccountClauses();
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Clauses should be retrieved');
    }

    @isTest
    static void testCreateAccountContract() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        List<Account_Contract_Clause__c> clauses = [SELECT Id FROM Account_Contract_Clause__c];
        
        Test.startTest();
        Id contractId = AccountContractController.createAccountContract(testAccount.Id, new List<Id>{clauses[0].Id, clauses[1].Id});
        Test.stopTest();

        System.assertNotEquals(null, contractId, 'Contract should be created');
        
        List<Account_Contract_Clause__c> updatedClauses = [SELECT Id, Account_Contract__c FROM Account_Contract_Clause__c WHERE Id IN :clauses];
    }

    @isTest
    static void testCreateContractClauseFile() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        List<Account_Contract_Clause__c> clauses = [SELECT Id, Name FROM Account_Contract_Clause__c];
        
        Id contractId = AccountContractController.createAccountContract(testAccount.Id, new List<Id>{clauses[0].Id});
        
        List<String> clauseNames = new List<String>();
        for (Account_Contract_Clause__c clause : clauses) {
            clauseNames.add(clause.Name);
        }
        
        Test.startTest();
        AccountContractController.createContractClauseFile(contractId, clauseNames);
        Test.stopTest();
        
        ContentVersion file = [SELECT Id, Title FROM ContentVersion WHERE FirstPublishLocationId = :contractId LIMIT 1];
        System.assertEquals('Selected Account Contract Clauses', file.Title, 'File should be created with correct title');
    }
}