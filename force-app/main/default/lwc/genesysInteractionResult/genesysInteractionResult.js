/*********************************************************************************************************************************
@ Name:         GenesysInteractionResult
@ Version:      1.0
@ Author:       ....
@ Purpose:      Consent form for Genesys  
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: ../../../???/created the lwc
@               : 17/10/2025 / vadhanak voun / US-0033570 - Genesys - Consent Capture Custom Label
*********************************************************************************************************************************/
import { LightningElement, api, track } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';
import invokeFlow from '@salesforce/apex/FlowInvoker.invoke';
import TRUSTED_ORIGINS_LABEL from '@salesforce/label/c.Trusted_Origins';
import customLabel from 'c/customLabels';

const DEBUG = false;
const TRUSTED_ORIGINS = TRUSTED_ORIGINS_LABEL.split(',').map(o => o.trim());

// Task validator (00T keyprefix, 15/18 chars, alphanumeric)
const looksLikeTaskId = (v) =>
    typeof v === 'string' &&
    v.startsWith('00T') &&
    /^[a-zA-Z0-9]+$/.test(v) &&
    (v.length === 15 || v.length === 18);

export default class GenesysInteractionResult extends LightningElement {
    @api interactionId;
    @api region;
    @api userConsent = null;    // true | false | null Added for tri-state logic. 
    @api userConsentResponse = 'Blank'; // "Yes" | "No" | "Blank" Added for tri-state logic.
    @api queueName;
    @api backendFlowApiName;
    @api recordingState;
    @api participantIds = [];
    @api participantId;

    // Expose the Task/Activity Id created by Genesys
    @api taskId;

    @api selectedContactId;

    @track messages = [];
    @track showConsent = false;
    @track isFlowInProgress = false;
    @track isNavigating = false;

    label = customLabel;
    navTimeoutId;
    pendingStationData = null;
    interactionStateMap = new Map();
    lastProcessedInteractionId = null;

    // Remember Task by interaction for reuse
    taskByInteraction = new Map();

    consentText = '';

    get requiresConsent() {
        //const consentQueues = ['AT', 'BEFR', 'BENL', 'CH', 'ES', 'FR', 'IE', 'IT', 'NL', 'PL'];
        //NK:17/10/2025:US-0033570
        const consentQueues = this.label.GenesyQueueList.split(",");

        const queuePrefix = this.queueName?.trim().toUpperCase().split('_')[0];
        const result = consentQueues.includes(queuePrefix);
        if (DEBUG) console.log('[Consent] queuePrefix:', queuePrefix, '→ requiresConsent:', result);
        return result;
    }

    doTranslation(key) {
        // String value = Label.get('', 'ConsentText', 'fr');
        // System.debug('ds>>> value: ' + value);
        const queuePrefix = this.queueName?.trim().toUpperCase().split('_')[0];
        
        // Translation dictionary
        const translations = {
            en: {
                consentText: this.label.GeneysConsentText_EN
            },
            de: {
                consentText: this.label.GeneysConsentText_DE
            },
            it: {
                consentText: this.label.GeneysConsentText_IT
            },
            fr: {
                consentText: this.label.GeneysConsentText_FR
            },
            befr: {
                consentText: this.label.GeneysConsentText_FR
            },
            es: {
                consentText: this.label.GeneysConsentText_ES
            },
        };

        // Current language
        let currentLang = 'en';
        
        if (queuePrefix) {
            currentLang = queuePrefix?.toLowerCase() || 'en';
        }
        
        return translations[currentLang][key] || key;
    }

    connectedCallback() {
        if (DEBUG) console.log('[Lifecycle] connectedCallback fired');
        window.addEventListener('message', this.handleMessage);
    }

    disconnectedCallback() {
        if (DEBUG) console.log('[Lifecycle] disconnectedCallback fired — cleaning up');
        window.removeEventListener('message', this.handleMessage);
        this.clearNavTimeout();
        this.interactionStateMap = new Map();
    }

    clearNavTimeout() {
        if (this.navTimeoutId) {
            clearTimeout(this.navTimeoutId);
            this.navTimeoutId = null;
        }
    }

    // Get Task Id from common Genesys shapes
    extractTaskId(obj) {
        if (!obj || typeof obj !== 'object') return null;
        const candidates = [
            obj?.returnValue?.recordId,
            obj?.recordId,
            obj?.data?.returnValue?.recordId,
            obj?.data?.recordId
        ].filter(Boolean);

        const id = candidates.find(looksLikeTaskId);
        return id || null;
    }

    // Publish Task Id (only if truly changed)
    setTaskId(taskId) {
        if (!taskId || taskId === this.taskId) return;

        this.taskId = taskId;
        if (this.interactionId) {
            this.taskByInteraction.set(this.interactionId, taskId);
        }

        if (DEBUG) console.log('[CallLog] Captured Task/Activity Id:', taskId, 'for interaction', this.interactionId);
        this.dispatchEvent(new FlowAttributeChangeEvent('taskId', this.taskId));
    }

    handleMessage = (event) => {
        if (!TRUSTED_ORIGINS.includes(event.origin)) {
            console.warn('[Security] Blocked message from untrusted origin:', event.origin);
            return;
        }

        const data = event.data;
        if (
            typeof data === 'object' &&
            data.methodName === 'publish' &&
            data.args?.eventName === 'purecloud__ClientEvent__c'
        ) {
            const message = typeof data.args.message === 'object' ? data.args.message : {};
            const payload = typeof message.data === 'object' ? message.data : {};
            const category = message.category;
            const type = message.type;

            if (DEBUG) console.log('[Genesys] Message received:', message);
            const callLogCandidate = payload?.returnValue ? payload : message;
            const foundTaskId = this.extractTaskId(callLogCandidate);
            if (foundTaskId) {
                this.setTaskId(foundTaskId);
            }
            if (type === 'Interaction') {
                if (category === 'add') {
                    if (DEBUG) console.log('[Genesys] category: add → processing new interaction');
                    this.processStationData(payload);
                } else if (category === 'change' && payload?.old && payload?.new) {
                    const oldConnected = payload.old.isConnected;
                    const newConnected = payload.new.isConnected;
                    const direction = payload.new.direction;

                    if (DEBUG) console.log('[Genesys] category: change → old.isConnected:', oldConnected, ', new.isConnected:', newConnected);

                    if (oldConnected === false && newConnected === true && direction === 'Outbound') {
                        const currentId = payload.new.id;
                        if (currentId === this.lastProcessedInteractionId) {
                            if (DEBUG) console.log('[Throttle] Skipping duplicate interaction:', currentId);
                            return;
                        }
                        this.lastProcessedInteractionId = currentId;

                        if (DEBUG) console.log('[Genesys] Detected connection state change → processing');

                        const participants = payload.new.participants || [];
                        const anyParticipant = participants.find(p => p && p.id);
                        this.participantId = anyParticipant ? anyParticipant.id : null;
                        this.dispatchEvent(new FlowAttributeChangeEvent('participantId', this.participantId));
                        
                        //const externalParticipants = participants.filter(p => p.purpose === 'external');
                        //this.participantIds = externalParticipants.map(p => p.id);
                        //this.dispatchEvent(new FlowAttributeChangeEvent('participantIds', this.participantIds));

                        this.processStationData(payload.new);
                    }
                } else {
                    if (DEBUG) console.log('[Genesys] Ignored category:', category);
                }
            }
        }
    };

    processStationData(stationData) {
        const {
            id: interactionId,
            direction,
            isConnected,
            queueName: rawQueueName,
            recordingState
        } = stationData;

        const state = this.interactionStateMap.get(interactionId) || {
            isConnected: false,
            hasFlowRun: false
        };

        if (DEBUG) {
            console.log(`[Genesys] Processing interactionId: ${interactionId}`);
            console.log(`[Genesys] Previous state:`, state);
            console.log(`[Genesys] New direction=${direction}, isConnected=${isConnected}`);
        }

        this.interactionId = interactionId;
        this.dispatchEvent(new FlowAttributeChangeEvent('interactionId', interactionId));

        const queue = stationData?.participants?.[0]?.queueName || rawQueueName || 'Unknown';
        this.queueName = queue;
        this.dispatchEvent(new FlowAttributeChangeEvent('queueName', queue));

        this.recordingState = recordingState || 'unknown';
        this.dispatchEvent(new FlowAttributeChangeEvent('recordingState', this.recordingState));

        this.pendingStationData = stationData;

        if (stationData?.participants?.length) {
            const anyParticipant = stationData.participants.find(p => p && p.id);
            const id = anyParticipant ? anyParticipant.id : null;
            if (id && id !== this.participantId) {
                this.participantId = id;
                this.dispatchEvent(new FlowAttributeChangeEvent('participantId', this.participantId));
            }
        }
       /* if (stationData?.participants?.length) {
            const externalParticipants = stationData.participants.filter(p => p.purpose === 'external');
            const ids = externalParticipants.map(p => p.id);
            if (JSON.stringify(ids) !== JSON.stringify(this.participantIds)) {
                this.participantIds = ids;
                this.dispatchEvent(new FlowAttributeChangeEvent('participantIds', this.participantIds));
            }
        }*/

        const isNewConnection = !state.isConnected && isConnected;
        const shouldRunFlow =
            direction === 'Outbound' &&
            isNewConnection &&
            this.requiresConsent &&
            !state.hasFlowRun;

        if (DEBUG) {
            console.log(`[Genesys] isNewConnection: ${isNewConnection}`);
            console.log(`[Genesys] shouldRunFlow: ${shouldRunFlow}`);
            console.log(`[Genesys] backendFlowApiName: ${this.backendFlowApiName}`);
        }

        if (shouldRunFlow && this.backendFlowApiName) {
            if (DEBUG) console.log('[Genesys] Invoking backend flow...');
            this.startBackendFlow();
            this.interactionStateMap.set(interactionId, {
                ...state,
                isConnected,
                hasFlowRun: true
            });

            if (this.requiresConsent) {
                this.consentText = this.doTranslation('consentText');
                this.showConsent = true;
            } else {
                this.processInteraction();
            }
            console.log('this.requiresConsent:' + this.requiresConsent);
            console.log('this.showConsent:' + this.showConsent);
        } else {
            this.interactionStateMap.set(interactionId, {
                ...state,
                isConnected
            });
        }

        // If a call log arrived earlier, keep exposing it for this interaction
        const knownTaskId = this.taskByInteraction.get(interactionId);
        if (knownTaskId) this.setTaskId(knownTaskId);
    }

    async startBackendFlow() {
        this.isFlowInProgress = true;
        try {
            if (DEBUG) {
                console.log('[Flow] Starting backend flow with:', {
                    interactionId: this.interactionId,
                    queueName: this.queueName,
                    recordingState: this.recordingState,
                    participantId: this.participantId
                });
            }

            await invokeFlow({
                flowApiName: this.backendFlowApiName,
                inputVariables: [
                    { name: 'interactionId', type: 'String', value: this.interactionId },
                    { name: 'queueName', type: 'String', value: this.queueName }
                ]
            });

            if (DEBUG) console.log('[Flow] Backend flow successfully invoked');
        } catch (error) {
            console.error('[Flow] Error invoking backend flow:', error?.body?.message || error);
        } finally {
            this.isFlowInProgress = false;
        }
    }

    handleConsentYes() {
        if (DEBUG) console.log('[Consent] User consented');
        this.userConsentResponse = 'Y'; // added for tri-state logic.
        this.userConsent = true;
        this.dispatchEvent(new FlowAttributeChangeEvent('userConsentResponse', this.userConsentResponse));
        this.dispatchEvent(new FlowAttributeChangeEvent('userConsent', this.userConsent));
        this.showConsent = false;
        this.processInteraction();
        // this.updateConsentRecord('Y');
    }

    handleConsentNo() {
        if (DEBUG) console.log('[Consent] User denied consent');
        this.userConsentResponse = 'N'; // added for tri-state logic.
        this.userConsent = false;
        this.dispatchEvent(new FlowAttributeChangeEvent('userConsentResponse', this.userConsentResponse));
        this.dispatchEvent(new FlowAttributeChangeEvent('userConsent', this.userConsent));
        this.showConsent = false;
        this.processInteraction();
        // this.updateConsentRecord('N');
    }

    // updateConsentRecord(consentRecordOption) {
    //     const payload = new CustomEvent('updateconsentrecord', {
    //         detail: {
    //             consentToRecord: consentRecordOption, 
    //             selectedContactId: this.selectedContactId,
    //             interactionId: this.lastProcessedInteractionId
    //         }
    //     });
    //     this.dispatchEvent(payload);
    // }

    processInteraction() {
        if (DEBUG) console.log('[Interaction] Navigating immediately to next flow screen');
        try {
            this.dispatchEvent(new FlowNavigationNextEvent());
        } catch (err) {
            console.warn('[Interaction] FlowNavigationNextEvent failed, using FinishEvent instead', err);
            this.dispatchEvent(new FlowNavigationFinishEvent());
        }
    }

    get hasDelay() {
        return this.isNavigating;
    }
}