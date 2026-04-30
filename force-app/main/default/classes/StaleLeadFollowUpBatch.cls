/**
 * @description Batch job that generates follow-up Tasks for all open Leads
 *              that have been open for more than 60 days.
 *              For each stale lead, creates a Task with subject "Close the Lead or mark it Bogus.",
 *              assigned to the lead owner, with a due date 2 days from creation.
 *              Run via: Database.executeBatch(new StaleLeadFollowUpBatch(), 200);
 */
public with sharing class StaleLeadFollowUpBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final String TASK_SUBJECT = 'Close the Lead or mark it Bogus.';
    private static final String TASK_PRIORITY = 'High';
    private static final Integer DAYS_OPEN_THRESHOLD = 60;
    private static final Integer DUE_DATE_OFFSET = 2;

    private Integer tasksCreated = 0;
    private Integer tasksFailed = 0;

    /**
     * @description Returns open, non-converted Leads created more than 60 days ago.
     * @param context Batch context provided by the platform.
     * @return Database.QueryLocator scoped to stale open Lead records.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        Date thresholdDate = Date.today().addDays(-DAYS_OPEN_THRESHOLD);
        return Database.getQueryLocator(
            'SELECT Id, OwnerId FROM Lead WHERE IsConverted = false AND CreatedDate <= :thresholdDate WITH USER_MODE'
        );
    }

    /**
     * @description Creates a follow-up Task for each stale Lead in the current chunk.
     * @param context Batch context provided by the platform.
     * @param scope   List of Lead records in the current batch chunk.
     */
    public void execute(Database.BatchableContext context, List<Lead> scope) {
        Date dueDate = Date.today().addDays(DUE_DATE_OFFSET);
        List<Task> tasksToInsert = new List<Task>();

        for (Lead lead : scope) {
            Task followUpTask = new Task();
            followUpTask.Subject = TASK_SUBJECT;
            followUpTask.OwnerId = lead.OwnerId;
            followUpTask.WhoId = lead.Id;
            followUpTask.ActivityDate = dueDate;
            followUpTask.Priority = TASK_PRIORITY;
            followUpTask.Status = 'Not Started';
            tasksToInsert.add(followUpTask);
        }

        List<Database.SaveResult> saveResults = Database.insert(tasksToInsert, false, AccessLevel.USER_MODE);

        for (Database.SaveResult result : saveResults) {
            if (result.isSuccess()) {
                tasksCreated++;
            } else {
                tasksFailed++;
                for (Database.Error error : result.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'StaleLeadFollowUpBatch error: ' + error.getMessage());
                }
            }
        }
    }

    /**
     * @description Logs a final summary of created vs. failed Tasks once all chunks complete.
     * @param context Batch context provided by the platform.
     */
    public void finish(Database.BatchableContext context) {
        System.debug(LoggingLevel.INFO,
            'StaleLeadFollowUpBatch complete. Tasks created: ' + tasksCreated + ', Failed: ' + tasksFailed);
    }
}