/*********************************************************************************************************************************
@ Class:          GleanChatHttpRequest
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0033581 - 3. Connect Glean Agent from chat component
@ Test Class:     GleanAgentControllerTest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.10.2025 / Sophal Noch /  Created the method.
*********************************************************************************************************************************/
public with sharing class GleanChatHttpRequest {

    private static final String TXT_DEFAULT = 'DEFAULT';
    private static final String TXT_USER = 'USER';
    private static final String TXT_CONTENT = 'CONTENT';

    private String agentId;
    private List<Message> messages;
    private String chatId;

    public GleanChatHttpRequest(String agentId, String userMessage, String chatId) {
        this.agentId = agentId;
        this.chatId = chatId;

        // Build fragments
        Fragment fragment = new Fragment();
        fragment.text = userMessage;

        // Build agentConfig
        AgentConfig config = new AgentConfig();
        config.agent = TXT_DEFAULT;
        config.mode = TXT_DEFAULT;

        // Build message
        Message msg = new Message();
        msg.author = TXT_USER;
        msg.messageType = TXT_CONTENT;
        msg.hasMoreFragments = false;
        msg.agentConfig = config;
        msg.fragments = new List<Fragment>{ fragment };

        this.messages = new List<Message>{ msg };
    }

    private class Message {
        private String author;
        private String messageType;
        private Boolean hasMoreFragments;
        private AgentConfig agentConfig;
        private List<Fragment> fragments;
    }

    private class AgentConfig {
        private String agent;
        private String mode;
    }

    private class Fragment {
        private String text;
    }

    // Helper to return JSON body
    public String toJson() {
        return JSON.serialize(this);
    }
}