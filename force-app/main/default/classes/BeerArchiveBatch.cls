/**
 * @description Batch job that archives Beer__c records whose Tags__c field equals "Archive".
 *              Sets Status__c = 'Archive' on each matching record.
 *              Schedule via: Database.executeBatch(new BeerArchiveBatch(), 200);
 */
public with sharing class BeerArchiveBatch implements Database.Batchable<SObject>, Database.Stateful {

    public enum BeerStatus {
        AVAILABLE,
        ARCHIVE
    }

    private static final Map<BeerStatus, String> STATUS_LABEL = new Map<BeerStatus, String>{
        BeerStatus.AVAILABLE => 'Available',
        BeerStatus.ARCHIVE   => 'Archive'
    };

    private Integer recordsProcessed = 0;
    private Integer recordsFailed = 0;

    public Database.QueryLocator start(Database.BatchableContext context) {
        String archiveLabel = STATUS_LABEL.get(BeerStatus.ARCHIVE);
        return Database.getQueryLocator(
            'SELECT Id, Tags__c, Status__c FROM Beer__c WHERE Tags__c = :archiveLabel AND Status__c != :archiveLabel WITH USER_MODE'
        );
    }

    public void execute(Database.BatchableContext context, List<Beer__c> scope) {
        String archiveLabel = STATUS_LABEL.get(BeerStatus.ARCHIVE);
        for (Beer__c beer : scope) {
            beer.Status__c = archiveLabel;
        }

        List<Database.SaveResult> results = Database.update(scope, false, AccessLevel.USER_MODE);

        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                recordsProcessed++;
            } else {
                recordsFailed++;
                for (Database.Error error : result.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'BeerArchiveBatch error on record ' + result.getId() + ': ' + error.getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug(LoggingLevel.INFO, 'BeerArchiveBatch complete. Archived: ' + recordsProcessed + ', Failed: ' + recordsFailed);
    }
}