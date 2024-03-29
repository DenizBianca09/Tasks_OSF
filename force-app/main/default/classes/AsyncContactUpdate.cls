public class AsyncContactUpdate implements Queueable {
    private List<Contact> contactsToProcess;

    public AsyncContactUpdate(List<Contact> contactsToProcess) {
        this.contactsToProcess = contactsToProcess;
    }

    public static void enqueueContacts(List<Contact> contactsToProcess) {
        AsyncContactUpdate job = new AsyncContactUpdate(contactsToProcess);
        System.enqueueJob(job);
    }

    public void execute(QueueableContext context) {
        Map<Id, String> accountIdToPrimaryPhone = new Map<Id, String>();

        // Presupunem că fiecare contact din lista procesată este un contact primar și are numărul de telefon care trebuie replicat
        for (Contact contact : contactsToProcess) {
            accountIdToPrimaryPhone.put(contact.AccountId, contact.Primary_Contact_Phone__c);
        }

        // Identificăm toate contactele din aceste conturi pentru a le actualiza
        List<Contact> allContactsForTheseAccounts = [
            SELECT Id, AccountId, Primary_Contact_Phone__c 
            FROM Contact 
            WHERE AccountId IN :accountIdToPrimaryPhone.keySet()
        ];

        // Pregătim lista de contacte de actualizat
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact contact : allContactsForTheseAccounts) {
            String newPrimaryPhone = accountIdToPrimaryPhone.get(contact.AccountId);
            if (newPrimaryPhone != null && contact.Primary_Contact_Phone__c != newPrimaryPhone) {
                contact.Primary_Contact_Phone__c = newPrimaryPhone;
                contactsToUpdate.add(contact);
            }
        }

        // Actualizăm contactele în Salesforce
        if (!contactsToUpdate.isEmpty()) {
            if (Schema.sObjectType.Contact.fields.Primary_Contact_Phone__c.isUpdateable()) {
                Database.SaveResult[] updateResults = Database.update(contactsToUpdate, false);
                // Aici ar trebui să gestionați orice erori rezultate din actualizare, dacă este necesar
            } else {
                System.debug('Lipsă permisiuni de actualizare pe câmpul Primary_Contact_Phone__c al obiectului Contact.');
            }
        }
    }
}
