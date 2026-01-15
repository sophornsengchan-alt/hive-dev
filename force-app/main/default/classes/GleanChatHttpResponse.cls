/*********************************************************************************************************************************
@ Class:          GleanChatHttpResponse
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0033581 - 3. Connect Glean Agent from chat component
@ Test Class:     GleanAgentControllerTest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.10.2025 / Sophal Noch /  Created the method.
*********************************************************************************************************************************/
public with sharing class GleanChatHttpResponse {


    private static final String TXT_CONTENT = 'CONTENT';
    private static final String EMPTY_STRING = '';

    // Top-level fields
    private List<Message> messages;
    private String chatId;
    private List<String> followUpPrompts;

    // Convenience: parse JSON into typed model
    public static GleanChatHttpResponse parse(String json) {
        return (GleanChatHttpResponse) System.JSON.deserialize(json, GleanChatHttpResponse.class);
    }

    /**
     * @description Extracts and concatenates all text content from chat response messages
     * @return String containing the complete chat response text
     * @throws None
     */
    public String getChatResponseText() {
        List<String> listResponse = new List<String>();
        if (messages != null && !messages.isEmpty()) {
            for (Message msg : messages) {
                listResponse.add(getMessageFragment(msg));
            }
        }
        return String.join(listResponse, EMPTY_STRING);
    }
    private String getMessageFragment(Message msg){
        List<String> listText = new List<String>();
        if(msg?.messageType == TXT_CONTENT && msg?.fragments != null && !msg?.fragments.isEmpty()){
            for (Fragment fr : msg.fragments) {
                if (String.isNotBlank(fr.text)) {
                    listText.add(fr.text);
                }
            }
        }
        return String.join(listText, EMPTY_STRING);
    }

    public String getChatId(){
        return chatId;
    }

    // Message-level model
    private class Message {
        private String author;
        private List<Fragment> fragments;

        private String messageId;
        private String messageTrackingToken;
        private String messageType;

        private String stepId;
        private String workflowId;
        private String stepRunId;
        private String workflowTraceId;
        private AgentTraceInfo agentTraceInfo;
        private String workflowRunId;

        // Some messages also include citations at the message level
        private List<Citation> citations;
    }

    private class AgentTraceInfo {
        private String traceId;
        private Long startTimeMillis;
    }

    // Fragment: text, citation, or structured results
    private class Fragment {
        private String text;
        private Citation citation;
        private List<StructuredResult> structuredResults;
    }

    private class StructuredResult {
        private DocumentResult document;
    }

    // Document + metadata
    private class DocumentResult {
        private String id;
        private String datasource;
        private String docType;
        private String title;
        private String url;

        private DocumentMetadata metadata;

        // Present for some GDrive docs
        private ParentDocument parentDocument;

        // These appear on some documents (sometimes within metadata)
        private String datasourceId;
        // private Map<String, Object> interactions; // not usable now, make sure we know all the problem before enable
        private String documentCategory;

        // Optional fields that may appear on some docs
        private String visibility;
        private Person author;
        private Person owner;
        private Person assignedTo;
        private Person updatedBy;
    }

    private class DocumentMetadata {
        private String datasource;
        private String datasourceInstance;
        private String objectType;
        private String mimeType;

        private String documentId;
        private String loggingId;
        private String createTime;
        private String updateTime;

        // Optional nested people and visibility context seen in HubTV docs
        private Person author;
        private Person owner;
        private Person assignedTo;
        private Person updatedBy;
        private String visibility;

        // Optional container context seen in GDrive docs
        private String container;
        private String containerId;
        private String datasourceId;

        // private Map<String, Object> interactions; // not usable now, make sure we know all the problem before enable
        private String documentCategory;
    }

    private class ParentDocument {
        private String id;
        private String datasource;
        private String docType;
        private String title;
        private String url;
    }

    private class Person {
        private String name;
        private String obfuscatedId;
        private PersonMetadata metadata;
    }

    private class PersonMetadata {
        private String lastExtensionUse;
        private String loggingId;
    }

    // Citations (message-level or inside fragment)
    private class Citation {
        private String trackingToken;
        private SourceDocument sourceDocument;
        private List<ReferenceRange> referenceRanges;
    }

    private class SourceDocument {
        private String id;
        private String datasource;
        private String title;
        private String url;
        private DocumentMetadata metadata;
    }

    private class ReferenceRange {
        private TextRange textRange;
    }

    private class TextRange {
        private Integer startIndex;
        private Integer endIndex;
    }
}