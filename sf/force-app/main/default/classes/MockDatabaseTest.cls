@IsTest
public with sharing class MockDatabaseTest {

    /** DML Tests */
    @IsTest
    public static void testInsert() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        Account insertedAcct = (Account) mockDb.db.get('Account').get(a.Id);

        Assert.isNotNull(mockDb.db.get('Account').get(a.Id), 'Account was not inserted');
    }

    @IsTest
    public static void testInsertList() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(new List<SObject>{a, b});

        Account insertedAcctA = (Account) mockDb.db.get('Account').get(a.Id);
        Account insertedAcctB = (Account) mockDb.db.get('Account').get(b.Id);

        Assert.isNotNull(insertedAcctA, 'Account A was not inserted');
        Assert.isNotNull(insertedAcctB, 'Account B was not inserted');
    }

    @IsTest
    public static void testUpdate() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        a.Name = 'Test2';
        mockDb.doUpdate(a);

        Account updatedAcct = (Account) mockDb.db.get('Account').get(a.Id);

        Assert.areEqual('Test2', updatedAcct.Name, 'Account was not updated');
    }

    /** SOQL Tests */
    @IsTest
    public static void testQuerySingle() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account');
        Account queriedAcct = queriedAccts[0];
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.isNotNull(queriedAcct, 'Account was not queried');
    }

    @IsTest
    public static void testQueryMultiple() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account');

        Assert.isNotNull(queriedAccts, 'Accounts were not queried');
        Assert.areEqual(2, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testInsertMultiple() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(new List<SObject>{a, b});

        Account insertedAcctA = (Account) mockDb.db.get('Account').get(a.Id);
        Account insertedAcctB = (Account) mockDb.db.get('Account').get(b.Id);

        Assert.isNotNull(insertedAcctA, 'Account A was not inserted');
        Assert.isNotNull(insertedAcctB, 'Account B was not inserted');
    }

    @IsTest
    public static void testParentSubQuery() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );

        mockDb.doInsert(con);

        List<Contact> queriedCons = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact');
        Contact queriedCon = queriedCons[0];
        Assert.areEqual(1, queriedCons.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedCon.Account.Name, 'Expected account name to be \'Test\'');
        Assert.areEqual('Steve', queriedCon.FirstName, 'Expected first name to be \'Steve\'');
        Assert.areEqual('Banner', queriedCon.LastName, 'Expected last name to be \'Banner\'');
        Assert.areEqual(con.Id, queriedCon.Id, 'Expected queried contact to be the same as inserted contact');
    }

    @IsTest
    static void testChildSubQuery(){
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = acct.Id
        );

        mockDb.doInsert(con);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts) FROM Account');
        Account queriedAcct = queriedAccts[0];
        Contact queriedCon = queriedAcct.Contacts[0];

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(1, queriedAcct.Contacts.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedAcct.Name, 'Expected account name to be \'Test\'');
        Assert.areEqual('Steve', queriedCon.FirstName, 'Expected first name to be \'Steve\'');
        Assert.areEqual('Banner', queriedCon.LastName, 'Expected last name to be \'Banner\'');
        Assert.areEqual(con.Id, queriedCon.Id, 'Expected queried contact to be the same as inserted contact');
   
    }

    @IsTest
    public static void testChildSubQueryMultiple() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<Contact> conList = new List<Contact>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            conList.add(con);
        }
        mockDb.doInsert(conList);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts) FROM Account');
        Account queriedAcct = queriedAccts[0];

        Map<String, sObject> mockContacts = (Map<String, sObject>) mockDb.db.get('Contact');

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(5, queriedAcct.Contacts.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedAcct.Name, 'Expected account name to be \'Test\'');

        Map<String, Boolean> queriedConNames = new Map<String, Boolean>();
        for(Integer i = 0; i < 5; i++) {
            queriedConNames.put(queriedAcct.Contacts[i].FirstName + queriedAcct.Contacts[i].LastName, true);
        }
        for(Integer i = 0; i < 5; i++) {
            Assert.areEqual('Steve', queriedAcct.Contacts[i].FirstName, 'Expected first name to be \'Steve\'');
            queriedConNames.put(queriedAcct.Contacts[i].FirstName + queriedAcct.Contacts[i].LastName, true);
        }

        for(Boolean foundName : queriedConNames.values()) {
            Assert.isTrue(foundName, 'Expected queried contact to be the same as inserted contact');
        }
    }

    @IsTest
    public static void testMutipleChildSubQueries() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<sObject> childRecords = new List<sObject>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            childRecords.add(con);
        }

        for(Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test' + i,
                AccountId = acct.Id,
                CloseDate = Date.today(),
                StageName = 'Prospecting'
            );
            childRecords.add(opp);
        }
        mockDb.doInsert(childRecords);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts), (SELECT Id, Name FROM Opportunities) FROM Account');
        Account queriedAcct = queriedAccts[0];

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(5, queriedAcct.Contacts.size(), 'Incorrect number of contacts queried');
        Assert.areEqual(5, queriedAcct.Opportunities.size(), 'Incorrect number of opportunities queried');
        Assert.areEqual('Test', queriedAcct.Name, 'Expected account name to be \'Test\'');

        Map<String, Boolean> queriedConNames = new Map<String, Boolean>();
        for(Integer i = 0; i < 5; i++) {
            queriedConNames.put(queriedAcct.Contacts[i].FirstName + queriedAcct.Contacts[i].LastName, true);
        }
        for(Integer i = 0; i < 5; i++) {
            Assert.areEqual('Steve', queriedAcct.Contacts[i].FirstName, 'Expected first name to be \'Steve\'');
            queriedConNames.put(queriedAcct.Contacts[i].FirstName + queriedAcct.Contacts[i].LastName, true);
        }

        for(Boolean foundName : queriedConNames.values()) {
            Assert.isTrue(foundName, 'Expected queried contact to be the same as inserted contact');
        }

        Map<String, Boolean> queriedOppNames = new Map<String, Boolean>();
        for(Integer i = 0; i < 5; i++) {
            queriedOppNames.put(queriedAcct.Opportunities[i].Name, true);
        }
        for(Integer i = 0; i < 5; i++) {
            Assert.areEqual('Test' + i, queriedAcct.Opportunities[i].Name, 'Expected opportunity name to be \'Test' + i + '\'');
            queriedOppNames.put(queriedAcct.Opportunities[i].Name, true);
        }

        for(Boolean foundName : queriedOppNames.values()) {
            Assert.isTrue(foundName, 'Expected queried opportunity to be the same as inserted opportunity');
        }
    }

    @IsTest
    public static void testDisallowDuplicateSubQueries() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<sObject> childRecords = new List<sObject>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            childRecords.add(con);
        }

        for(Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test' + i,
                AccountId = acct.Id,
                CloseDate = Date.today(),
                StageName = 'Prospecting'
            );
            childRecords.add(opp);
        }
        mockDb.doInsert(childRecords);

        Boolean exceptionThrown = false;
        try {
            List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts), (SELECT Id, Name FROM Opportunities), (SELECT Id, Name FROM Opportunities WHERE Name = \'Test1\') FROM Account');
        } catch(QueryException e) {
            Assert.areEqual('Cannot follow the same aggregate relationship twice', e.getMessage(), 'Expected exception message to be \'Cannot follow the same aggregate relationship twice\'');
            exceptionThrown = true;
        } finally {
            Assert.isTrue(exceptionThrown, 'Expected exception to be thrown');
        }
    }

    @IsTest
    public static void testQueryWithWhereClause() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\'');
        Account queriedAcct = queriedAccts[0];
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.isNotNull(queriedAcct, 'Account was not queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseMultiple() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\'');
        Account queriedAcct = queriedAccts[0];
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.isNotNull(queriedAcct, 'Account was not queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseNone() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test3\'');
        Assert.areEqual(0, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseMultipleFields() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\' OR Name = \'Test2\'');
        Assert.areEqual(2, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseMultipleFieldsNone() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test3\' OR Name = \'Test4\'');
        Assert.areEqual(0, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseMultipleFieldsOne() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\' OR Name = \'Test4\'');
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithSubQueryInWhereClause() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = acct.Id
        );

        mockDb.doInsert(con);

        List<Contact> queriedCons = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Name = \'Test\')');
        Contact queriedCon = queriedCons[0];
        Assert.areEqual(1, queriedCons.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedCon.Account.Name, 'Expected account name to be \'Test\'');
        Assert.areEqual('Steve', queriedCon.FirstName, 'Expected first name to be \'Steve\'');
        Assert.areEqual('Banner', queriedCon.LastName, 'Expected last name to be \'Banner\'');
        Assert.areEqual(con.Id, queriedCon.Id, 'Expected queried contact to be the same as inserted contact');
    }

    @IsTest
    public static void testDuplicateFieldsQueried() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);
        Boolean exceptionThrown = false;
        try {
            List<Contact> queriedAccts = (List<Contact>) mockDb.query('SELECT Id, Name, Name FROM Account');
        } catch(QueryException e) {
            Assert.areEqual('Duplicate field selected', e.getMessage(), 'Expected exception message to be \'Duplicate field selected: Name\'');
            exceptionThrown = true;
        } finally {
            Assert.isTrue(exceptionThrown, 'Expected exception to be thrown');
        }
    }

    @IsTest
    public static void testQueryWithSubQueryInWhereClauseMultiple() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<Contact> conList = new List<Contact>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            conList.add(con);
        }
        mockDb.doInsert(conList);

        List<Contact> queriedCons = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Name = \'Test\')');
        Contact queriedCon = queriedCons[0];

        Map<String, sObject> mockContacts = (Map<String, sObject>) mockDb.db.get('Contact');

        Assert.areEqual(5, queriedCons.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedCon.Account.Name, 'Expected account name to be \'Test\'');

        Map<String, Boolean> queriedConNames = new Map<String, Boolean>();
        for(Integer i = 0; i < 5; i++) {
            queriedConNames.put(queriedCons[i].FirstName + queriedCons[i].LastName, true);
        }
        for(Integer i = 0; i < 5; i++) {
            Assert.areEqual('Steve', queriedCons[i].FirstName, 'Expected first name to be \'Steve\'');
            queriedConNames.put(queriedCons[i].FirstName + queriedCons[i].LastName, true);
        }

        for(Boolean foundName : queriedConNames.values()) {
            Assert.isTrue(foundName, 'Expected queried contact to be the same as inserted contact');
        }
    }
}