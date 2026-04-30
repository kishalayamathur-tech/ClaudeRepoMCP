/**
 * @description Test class for StaleLeadFollowUpBatch.
 *              Verifies that follow-up Tasks are created correctly for stale Leads.
 */
@isTest(seeAllData=false)
public class StaleLeadFollowUpBatchTest {

    @TestSetup
    static void setupTestData() {
        List<Lead> leadsToInsert = new List<Lead>();

        // Stale leads — will be backdated to 61 days ago
        for (Integer i = 0; i < 5; i++) {
            leadsToInsert.add(new Lead(
                FirstName = 'Stale',
                LastName  = 'Lead ' + i,
                Company   = 'Test Company ' + i,
                Status    = 'Open - Not Contacted'
            ));
        }

        // Recent lead — should NOT get a task
        leadsToInsert.add(new Lead(
            FirstName = 'Recent',
            LastName  = 'Lead',
            Company   = 'New Company',
            Status    = 'Open - Not Contacted'
        ));

        insert leadsToInsert;

        // Backdate the first 5 leads to simulate 61 days open
        List<Lead> staleLeads = [SELECT Id, CreatedDate FROM Lead WHERE LastName LIKE 'Lead %' WITH USER_MODE];
        Test.setCreatedDate(staleLeads[0].Id, DateTime.now().addDays(-61));
        Test.setCreatedDate(staleLeads[1].Id, DateTime.now().addDays(-61));
        Test.setCreatedDate(staleLeads[2].Id, DateTime.now().addDays(-61));
        Test.setCreatedDate(staleLeads[3].Id, DateTime.now().addDays(-61));
        Test.setCreatedDate(staleLeads[4].Id, DateTime.now().addDays(-61));
    }

    @isTest
    static void testBatch_CreatesTasksForStaleLeads() {
        Test.startTest();
        Database.executeBatch(new StaleLeadFollowUpBatch(), 200);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, Priority, ActivityDate, OwnerId, WhoId
                            FROM Task WITH USER_MODE];

        System.Assert.areEqual(5, tasks.size(), 'Expected 5 tasks for stale leads');

        for (Task task : tasks) {
            System.Assert.areEqual('Close the Lead or mark it Bogus.', task.Subject, 'Task subject should match');
            System.Assert.areEqual('High', task.Priority, 'Task priority should be High');
            System.Assert.areEqual(Date.today().addDays(2), task.ActivityDate, 'Due date should be 2 days from today');
            System.Assert.isNotNull(task.WhoId, 'Task should be linked to a Lead');
        }
    }

    @isTest
    static void testBatch_NoTasksForRecentLeads() {
        // Delete stale leads so only the recent one remains
        List<Lead> staleLeads = [SELECT Id FROM Lead WHERE LastName LIKE 'Lead %' WITH USER_MODE];
        delete staleLeads;

        Test.startTest();
        Database.executeBatch(new StaleLeadFollowUpBatch(), 200);
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WITH USER_MODE];
        System.Assert.areEqual(0, tasks.size(), 'No tasks should be created for recent leads');
    }

    @isTest
    static void testBatch_NoLeads_RunsWithoutError() {
        delete [SELECT Id FROM Lead WITH USER_MODE];

        Test.startTest();
        Database.executeBatch(new StaleLeadFollowUpBatch(), 200);
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WITH USER_MODE];
        System.Assert.areEqual(0, tasks.size(), 'No tasks should be created when there are no leads');
    }
}