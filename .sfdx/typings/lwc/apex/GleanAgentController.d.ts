declare module "@salesforce/apex/GleanAgentController.getAuthUrl" {
  export default function getAuthUrl(): Promise<any>;
}
declare module "@salesforce/apex/GleanAgentController.getAgentResponse" {
  export default function getAgentResponse(param: {agentId: any, userMessage: any, chatId: any}): Promise<any>;
}
declare module "@salesforce/apex/GleanAgentController.getChatById" {
  export default function getChatById(param: {chatId: any}): Promise<any>;
}
declare module "@salesforce/apex/GleanAgentController.isUserAuthorized" {
  export default function isUserAuthorized(): Promise<any>;
}
declare module "@salesforce/apex/GleanAgentController.getGleanAgentOptions" {
  export default function getGleanAgentOptions(): Promise<any>;
}
declare module "@salesforce/apex/GleanAgentController.getChatId" {
  export default function getChatId(): Promise<any>;
}
declare module "@salesforce/apex/GleanAgentController.getConversationStarters" {
  export default function getConversationStarters(param: {agentName: any}): Promise<any>;
}
declare module "@salesforce/apex/GleanAgentController.getAccountSummary" {
  export default function getAccountSummary(param: {accountId: any, accountName: any, oracleId: any}): Promise<any>;
}
