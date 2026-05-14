@RestResource(urlMapping='/mcp/createCase')
global with sharing class mcpCreateCase {
    global class ResponseWrapper {
    String recordNumber;
    String message;

    public ResponseWrapper(String recordNumber, String message) {
    this.recordNumber = recordNumber;
    this.message = message;
    }
}

@HttpPost
global static ResponseWrapper execute(String subject, String description, String priority, String contactId) {
    Case c = new Case(
        Subject = subject,
        Description = description,
        Priority = priority,
        Origin = 'Web',
        ContactId = contactId
    );
    insert c;
    Case newCase = [Select CaseNumber from Case where Id =: c.Id];
    return new ResponseWrapper (newCase.CaseNumber, 'Success: Case created');
    
}
}