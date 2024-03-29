global class OpportunityAmountScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        OpportunityAmountSummarizer batch = new OpportunityAmountSummarizer();
        Database.executeBatch(batch);
    }
}
