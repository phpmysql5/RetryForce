@isTest
public class AccountTriggerHandlerTest {

    @isTest
    static void testHighValueAccountOnInsert() {
        Account acc = new Account(Name = 'High Value Corp', AnnualRevenue = 50000);
        insert acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, acc.Is_High_Value__c, 'Account with AnnualRevenue > 10000 should be marked as high value');
    }

    @isTest
    static void testLowValueAccountOnInsert() {
        Account acc = new Account(Name = 'Low Value Corp', AnnualRevenue = 5000);
        insert acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, acc.Is_High_Value__c, 'Account with AnnualRevenue <= 10000 should not be marked as high value');
    }

    @isTest
    static void testNullRevenueOnInsert() {
        Account acc = new Account(Name = 'No Revenue Corp');
        insert acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, acc.Is_High_Value__c, 'Account with null AnnualRevenue should not be marked as high value');
    }

    @isTest
    static void testAccountUpdateBecomesHighValue() {
        Account acc = new Account(Name = 'Growing Corp', AnnualRevenue = 5000);
        insert acc;

        acc.AnnualRevenue = 15000;
        update acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, acc.Is_High_Value__c, 'Account updated to AnnualRevenue > 10000 should be marked as high value');
    }

    @isTest
    static void testAccountUpdateLosesHighValue() {
        Account acc = new Account(Name = 'Declining Corp', AnnualRevenue = 20000);
        insert acc;

        acc.AnnualRevenue = 100000;
        update acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, acc.Is_High_Value__c, 'Account updated to AnnualRevenue <= 1M should no longer be high value');
    }

    @isTest
    static void testBulkInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Account ' + i,
                AnnualRevenue = (i < 100) ? 2000000 : 500000
            ));
        }
        insert accounts;

        List<Account> highValue = [SELECT Id FROM Account WHERE Is_High_Value__c = true];
        List<Account> lowValue  = [SELECT Id FROM Account WHERE Is_High_Value__c = false];

        System.assertEquals(100, highValue.size(), 'Should have 100 high value accounts');
        System.assertEquals(100, lowValue.size(),  'Should have 100 low value accounts');
    }
}
