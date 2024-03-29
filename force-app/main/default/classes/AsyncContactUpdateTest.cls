@IsTest
private class AsyncContactUpdateTest {
    @IsTest
    static void testAsyncContactUpdate() {
        // Crearea datelor de test
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Crearea mai multor contacte pentru același cont
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'Test1', AccountId = testAccount.Id, Primary_Contact_Phone__c = '1234567890'),
            new Contact(LastName = 'Test2', AccountId = testAccount.Id)
            // Adaugă mai multe contacte dacă este necesar
        };
        insert contacts;

        // Setează un nou număr de telefon pentru contactul primar și pregătește procesarea asincronă
        Contact primaryContact = contacts[0];
        primaryContact.Primary_Contact_Phone__c = '0987654321';

        // Așteptăm ca procesarea asincronă să actualizeze numărul de telefon pentru toate contactele asociate contului
        Test.startTest();
        AsyncContactUpdate.enqueueContacts(new List<Contact>{primaryContact});
        Test.stopTest();

        // Verifică dacă numărul de telefon a fost actualizat pentru toate contactele de pe același cont
        List<Contact> updatedContacts = [SELECT Primary_Contact_Phone__c FROM Contact WHERE AccountId = :testAccount.Id];
        for (Contact cont : updatedContacts) {
            System.assertEquals('0987654321', cont.Primary_Contact_Phone__c, 'Numărul de telefon ar trebui să fie actualizat pentru toate contactele.');
        }
    }
}
