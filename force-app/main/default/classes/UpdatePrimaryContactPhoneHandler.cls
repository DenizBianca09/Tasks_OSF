public class UpdatePrimaryContactPhoneHandler {

    public static void handleBeforeInsertOrUpdate(List<Contact> newList, Map<Id, Contact> oldMap) {
        if (!Contact.sObjectType.getDescribe().isAccessible()) {
            System.debug('Lipsă permisiuni de acces pe obiectul Contact.');
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Contact con : newList) {
            if (con.Primary_Contact_Phone__c != null && con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }

        Map<Id, Contact> accountToExistingPrimary = new Map<Id, Contact>();
        for (Contact existingContact : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds AND Primary_Contact_Phone__c != null]) {
            accountToExistingPrimary.put(existingContact.AccountId, existingContact);
        }

        for (Contact con : newList) {
            Contact existingPrimary = accountToExistingPrimary.get(con.AccountId);
            if (existingPrimary != null && (Trigger.isInsert || (existingPrimary.Id != con.Id))) {
                con.addError('Error: Invalid Data. Review all error messages below to correct your data. There is a primary contact that already exists.');
            }
        }

        if (Contact.sObjectType.getDescribe().isUpdateable()) {
            AsyncContactUpdate.enqueueContacts(newList);
        } else {
            System.debug('Lipsă permisiuni de actualizare pe obiectul Contact.');
        }
    }
}
