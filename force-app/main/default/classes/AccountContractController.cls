public with sharing class AccountContractController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account_Contract_Clause__c> getAccountClauses() {
        Account acc = [SELECT BillingCountry FROM Account WHERE BillingCountry!=null LIMIT 1];
        return [SELECT Id, Name FROM Account_Contract_Clause__c WHERE Billing_Country__c = :acc.BillingCountry];
    }

    @AuraEnabled
    public static Id createAccountContract(Id accountId, List<Id> clauseIds) {
        if (accountId == null || clauseIds.isEmpty()) {
            throw new AuraHandledException('Invalid data provided.');
        }
        
        Account_Contract__c newContract = new Account_Contract__c(
            Name = 'New Account Contract - ' + System.today(),
            Account__c = accountId
        );
        insert newContract;

        List<Account_Contract_Clause__c> clausesToUpdate = [
            SELECT Id FROM Account_Contract_Clause__c WHERE Id IN :clauseIds
        ];
        for (Account_Contract_Clause__c clause : clausesToUpdate) {
            clause.Account_Contract__c = newContract.Id;
        }
        update clausesToUpdate;

        return newContract.Id;
    }

    @AuraEnabled
    public static void createContractClauseFile(Id contractId, List<String> clauseNames) {
        if (contractId == null || clauseNames.isEmpty()) {
            throw new AuraHandledException('Invalid data provided.');
        }

        ContentVersion file = new ContentVersion();
        file.Title = 'Selected Account Contract Clauses';
        file.PathOnClient = 'SelectedClauses.txt';
        file.VersionData = Blob.valueOf('Selected Account Contract Clauses:\n' + String.join(clauseNames, '\n'));
        file.FirstPublishLocationId = contractId;
        insert file;
    }
}