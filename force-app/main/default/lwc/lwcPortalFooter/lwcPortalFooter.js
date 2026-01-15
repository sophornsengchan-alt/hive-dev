/*********************************************************************************************************************************
@ Component:      lwcPortalFooter
@ Version:        1.0
@ Author:         Mony Nou
@ Purpose:        Display Footer Information with dynamic current year for all portals (ex: SEP, Influencer, etc)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 01.02.2022 / Mony Nou / US-0013139 - Seller Portal Footer, Display Current Year
@               14.07.2023 / Acmatac Seing / US-0013589 - Language localizations and referrer reporting for Bookings
*********************************************************************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
// import getPortalDomain from '@salesforce/apex/SEP_Helper.getPortalDomain';
import getPortalFooter from '@salesforce/apex/SEP_Helper.getPortalFooter';

// import PortalFooter_SEP from '@salesforce/label/c.PortalFooter_SEP';
// import PortalFooter_SEP_NA from '@salesforce/label/c.PortalFooter_SEP_NA';



export default class LwcPortalFooter extends LightningElement {

    @api portal; 

    /* Labels = { 
         PortalFooter_SEP, PortalFooter_SEP_NA
    };*/

    replace_str = '[Current year]';

    footer_sep = '';
    // footer_sep_eu = this.Labels.PortalFooter_SEP;
    // footer_sep_na = this.Labels.PortalFooter_SEP_NA;

    // isEUSEP = false;
    // isNASEP = false;
    // isAUSEP = false;

    get isSEP() {
        return (this.portal && this.portal != "" && this.portal == "eBay Seller Portal");
    }
    
    //MN-24122021-US-0010562
    //14.07.2023 / Acmatac Seing / US-0013589
    @wire(getPortalFooter, { selectedPortal: '$portal'})
    initComponent(result) {
        
        if(result.data) {   
            
            //console.log('**** data :: ', result.data);
            // console.log('**** portal :: ', this.portal);

            var cur_year = new Date().getFullYear();
            this.footer_sep = result.data.footer_str.replace(this.replace_str, cur_year);

            /* OLD-VERSION
            if (result.data.hasOwnProperty('isEUSEP')) this.isEUSEP = result.data.isEUSEP;
            if (result.data.hasOwnProperty('isNASEP')) this.isNASEP = result.data.isNASEP;
            if (result.data.hasOwnProperty('isAUSEP')) this.isAUSEP = result.data.isAUSEP;

            if (this.isEUSEP  || this.isAUSEP) {
                this.footer_sep = this.footer_sep_eu;
            }
            else if (this.isNASEP) {
                this.footer_sep = this.footer_sep_na;
            }
            var cur_year = new Date().getFullYear();
            this.footer_sep = this.footer_sep.replace(this.replace_str, cur_year);
            */

            
            

        } else if (result.error) {
            console.log('INIT PORTAL FOOTER ERROR :: ', result.error);
        }
    
    };
}