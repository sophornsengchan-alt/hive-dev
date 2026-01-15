@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
               
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"Timestamp":"2019-09-24T16:23:59.969Z","Ack":"PartialFailure","Errors":[{"ShortMessage":"One or more item id is invalid.","LongMessage":"Invalid or non-existent item.","ErrorCode":"10.15","SeverityCode":"Error","ErrorParameters":[{"Value":"29283382893800","ParamID":"0"}],"ErrorClassification":"RequestError"}],"Build":"E1119_CORE_APILW_19036190_R1","Version":"1119","Item":[{"ItemID":"382434713596","EndTime":"2019-10-12T14:56:34.000Z","ViewItemURLForNaturalSearch":"https://www.ebay.de/itm/THULE-Fahrradtraeger-EuroRide-942-3-Fahrraeder-Hecktraeger-Fahrradhalter-/382434713596","ListingType":"FixedPriceItem","Location":"Berlin","GalleryURL":"https://thumbs1.ebaystatic.com/pict/3824347135968080_7.jpg","PictureURL":["https://i.ebayimg.com/00/s/NjAwWDgwMA==/z/GZ8AAOSwaV1ddr4M/$_1.JPG?set_id=880000500F","https://i.ebayimg.com/00/s/MTIwMVgxNjAw/z/zaUAAOSwUORddr4L/$_1.JPG?set_id=880000500F"],"PrimaryCategoryID":"173830","PrimaryCategoryName":"Auto & Motorrad: Teile:Auto-Anbau- & -Zubehörteile:Reisen & Touring:Fahrradträger","BidCount":0,"ConvertedCurrentPrice":{"Value":299.35,"CurrencyID":"EUR"},"ListingStatus":"Active","TimeLeft":"P17DT22H32M35S","Title":"THULE | Fahrradträger EuroRide 942 für 3 Fahrräder | Heckträger Fahrradhalter","HitCount":58741,"Country":"DE","AutoPay":false,"ConditionID":1000,"ConditionDisplayName":"Neu","QuantityAvailableHint":"Limited","DiscountPriceInfo":{"OriginalRetailPrice":{"Value":535.5,"CurrencyID":"EUR"},"PricingTreatment":"STP","SoldOneBay":false,"SoldOffeBay":false}}]}');
        res.setStatusCode(200);
        return res;
    }
}