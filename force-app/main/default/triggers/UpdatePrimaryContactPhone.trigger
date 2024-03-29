trigger UpdatePrimaryContactPhone on Contact (before insert, before update) {
    // Delegăm logica către handler pentru a păstra trigger-ul curat
    UpdatePrimaryContactPhoneHandler.handleBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
}
