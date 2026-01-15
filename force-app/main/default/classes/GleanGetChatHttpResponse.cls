/*********************************************************************************************************************************
@ Class:          GleanGetChatHttpResponse
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0033813 - Feedback on Glean custom chat component - Parse and extract chat history
@ Test Class:     GleanAgentControllerTest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 2025-11-12 / Sophal Noch / Created the class and methods.
*********************************************************************************************************************************/
public with sharing class GleanGetChatHttpResponse {

    private static final String EMPTY_STRING = '';
    private static final String PROP_USER = 'USER';
    private static final String PROP_CONTENT = 'CONTENT';

    private ChatResult chatResult;
    private String trackingToken;
    

    // Convenience: parse JSON into typed model
    public static GleanGetChatHttpResponse parse(String json) {
        return (GleanGetChatHttpResponse) System.JSON.deserialize(json, GleanGetChatHttpResponse.class);
    }

    private class ChatResult {
        private Chat chat;
        private List<Role> roles;
        private String id;
        private Long createTime;
        private Person createdBy;
        private Long updateTime;
        private String name;
        private String agentId;
        private String status;
    }

    private class Chat {
        private List<Message> messages;
    }

    private class Message {
        private AgentConfig agentConfig;
        private String author;
        private List<Fragment> fragments;
        private String ts;
        private String messageId;
        private String messageTrackingToken;
        private String messageType;
        private String stepId;
        private String workflowId;
        private String stepRunId;
        private String workflowTraceId;
    }

    private class AgentConfig {
        private String agent;
        private String mode;
    }

    private class Fragment {
        private String text;
        private List<StructuredResult> structuredResults;
    }

    private class StructuredResult {
        private Document document;
    }

    private class Document {
        private String id;
    }

    private class Role {
        private SourceDocumentSpec sourceDocumentSpec;
        private Person person;
        private String role;
    }

    private class SourceDocumentSpec {
        private String ugcType;
        private String docType;
        private String ugcId;
    }

    private class Person {
        private String name;
        private String obfuscatedId;
    }

    /*********************************************************************************************************************************
    @ Method:         getChatItems
    @ Author:         Sophal Noch
    @ Purpose:        US-0033813 - Feedback on Glean custom chat component
    @ Change history: 12.11.2025 / Sophal Noch / Create method
    *********************************************************************************************************************************/
    public List<CustomChatItem> getChatItems() {
        List<CustomChatItem> customChatItems = new List<CustomChatItem>();
        
        if (chatResult?.chat?.messages == null || chatResult.chat.messages.isEmpty()) {
            return customChatItems;
        }
        
        for (Message msg : chatResult.chat.messages) {
            if (msg?.messageType != PROP_CONTENT) {
                continue;
            }
            
            Boolean isUser = PROP_USER.equals(msg?.author);
            String messageText = getMessageFromFragments(msg);
            
            if (String.isNotBlank(messageText)) {
                CustomChatItem item = new CustomChatItem(isUser, messageText);
                customChatItems.add(item);
            }
        }
        
        return customChatItems;
    }

    /**
     * @description Extract and concatenate text from message fragments
     * @param msg The message containing fragments to process
     * @return String The concatenated text from all fragments
     */
    private String getMessageFromFragments(Message msg) {
        if (msg?.fragments == null || msg.fragments.isEmpty()) {
            return EMPTY_STRING;
        }
        
        List<String> textParts = new List<String>();
        for (Fragment frag : msg.fragments) {
            if (String.isNotBlank(frag?.text)) {
                textParts.add(frag.text);
            }
        }
        
        return String.join(textParts, EMPTY_STRING);
    }    

    public class CustomChatItem {
        @AuraEnabled
        public Boolean isUser {get; set;}

        @AuraEnabled
        public String message {get; set;}
        
        public CustomChatItem(Boolean isUser, String message) {
            this.isUser = isUser != null ? isUser : false;
            this.message = message != null ? message : EMPTY_STRING;
        }
    }


}