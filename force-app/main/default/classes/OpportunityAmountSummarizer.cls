global class OpportunityAmountSummarizer implements Database.Batchable<sObject>, Database.Stateful {

    // This map will store the summarized amounts for each Account
    private Map<Id, AccountSummary> accountSummaryMap = new Map<Id, AccountSummary>();

    // Inner class to hold the summary information for each Account
    private class AccountSummary {
        public Decimal totalOpenAmount = 0;
        public Decimal totalClosedWonAmount = 0;
        public Decimal totalClosedLostAmount = 0;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all relevant Opportunities
        return Database.getQueryLocator([
            SELECT Id, Amount, StageName, AccountId 
            FROM Opportunity 
            WHERE (CreatedDate = LAST_N_DAYS:30 OR LastModifiedDate = LAST_N_DAYS:30)
            AND (StageName = 'Closed Won' OR StageName = 'Open' OR StageName = 'Closed Lost')

        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> opportunities) {
        // Iterate over the Opportunities and summarize the Amounts for each Account
        for (Opportunity opp : opportunities) {
            // Check if the accountSummaryMap already contains the AccountId
            if (!accountSummaryMap.containsKey(opp.AccountId)) {
                // If not, create a new AccountSummary object
                accountSummaryMap.put(opp.AccountId, new AccountSummary());
            }
            // Get the summary from the map
            AccountSummary summary = accountSummaryMap.get(opp.AccountId);
            // Add the amounts to the summary based on the StageName
            if (opp.StageName == 'Open') {
                summary.totalOpenAmount += opp.Amount;
            } else if (opp.StageName == 'Closed Won') {
                summary.totalClosedWonAmount += opp.Amount;
            } else if (opp.StageName == 'Closed Lost') {
                summary.totalClosedLostAmount += opp.Amount;
            }
        }
    }
    global void finish(Database.BatchableContext BC) {
        // After all batches are processed, send the emails to the primary contact for each account
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        // Loop through the summarized data and construct the emails
        for (Id accountId : accountSummaryMap.keySet()) {
            // Retrieve the primary contact for the account if there is one
            List<Contact> primaryContacts = [SELECT Id, Email FROM Contact WHERE AccountId = :accountId AND Is_Primary__c = true LIMIT 1];
            if (!primaryContacts.isEmpty()) {
                Contact primaryContact = primaryContacts.get(0);
                if (primaryContact != null && primaryContact.Email != null) {
                    // Construct the email message
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(primaryContact.Id); // Sets the target to a Contact
                    mail.setSaveAsActivity(false); // Don't log the email as an activity
                    mail.setSubject('Monthly Opportunity Summary');
                    
                    // Construct the email body with the summarized data
                    AccountSummary summary = accountSummaryMap.get(accountId);
                    String emailBody = 'The summary of opportunities for this month is: \n\n' +
                                       'Open: ' + summary.totalOpenAmount.format() + '\n' +
                                       'Closed Won: ' + summary.totalClosedWonAmount.format() + '\n' +
                                       'Closed Lost: ' + summary.totalClosedLostAmount.format();
                    
                    mail.setPlainTextBody(emailBody);
                    
                    emailsToSend.add(mail);
                }
            } else {
                // Tratează cazul în care nu există niciun contact principal găsit pentru contul curent
                System.debug('Nu există niciun contact principal pentru contul cu ID-ul: ' + accountId);
            }
        }
        
        // Send all emails in a single call
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }        
}
