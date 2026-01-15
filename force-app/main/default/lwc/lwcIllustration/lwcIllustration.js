import { LightningElement , api } from 'lwc';
import maintenance from './maintenance.html';
import noData from './noData.html';
import noConnection from './noConnection.html';
import noContent from './noContent.html';
import noEvent from './noEvent.html';
import noTask from './noTask.html';
import noPreview from './noPreview.html';
import notAvailableInLightning from './notAvailableInLightning.html';
import pageNotAvailable from './pageNotAvailable.html';
import walkthroughNotAvailable from './walkthroughNotAvailable.html';
const DEFAULTHEIGHT = '10';
export default class LwcIllustration extends LightningElement {
    tableHeightStyle='height: '+ DEFAULTHEIGHT +'rem;';

    @api message = '';
    @api type = '';
    @api fontSize;
    @api
    get height() {
        return this.tableHeightStyle;
    }

    set height(value) {
        this.tableHeightStyle = 'height: '+ value +'rem;'; 
    }  

    render(){
        if(this.fontSize != null && this.fontSize != '' && this.fontSize != undefined){
            this.fontSize = 'font-size: ' + this.fontSize
        }
        this.type = this.type != null ? this.type.toLowerCase() : '';
        if(this.type === 'maintenance'){
            return maintenance;
        }else if(this.type === 'no_connection'){
            return noConnection;
        }else if(this.type === 'not_in_lightning'){
            //not_available_in_lightning
            return notAvailableInLightning;
        }else if(this.type === 'page_not_available'){
            return pageNotAvailable;
        }else if(this.type === 'walkthrough_not_available'){
            return walkthroughNotAvailable;
        }else if(this.type === 'no_event'){
            return noEvent;
        }else if(this.type === 'no_task'){
            return noTask;
        }else if(this.type === 'no_content'){
            return noContent;
        }else if(this.type === 'no_preview'){
            return noPreview;
        } else{
            //(this.illustration === 'No Data') default if no illustration is provided
            return noData;
        }
    }
    
}