global class TH_Assignments {
    
    
    //-- IGNORED OFFSET/PAGE SIZES for combined collated results.
    public static final Integer NO_OFFSET = 0;
    public static final Integer MAX_RESULTS = 255;
    
    
    
    //-- #  #   #   #   #   #   #   #   #   #   #   #   #   #   #   #   #
    //-- internal result classes
    //-- #  #   #   #   #   #   #   #   #   #   #   #   #   #   #   #   #
    
    
    
    /**
     * Internal class to return counts of the trailhead assignments for the current user.
     * <p>Used in pagination</p>
     **/
    global class AssignmentCounts {
        AssignmentCounts(){
            this.numBadgeAssignments = 0;
            this.numTrailmixAssignments = 0;
            this.totalAssignments = 0;
        }

        @AuraEnabled public Integer numBadgeAssignments;
        @AuraEnabled public Integer numTrailmixAssignments;
        @AuraEnabled public Integer totalAssignments;
    }
    
    /**
     * Internal class that represents a generalized Trailhead assignment - Badge or TrailMix.
     **/
    global class TrailheadEntry implements Comparable{
        /** Id of the user assignment **/
     	@AuraEnabled public String Id;
     	/** Name of the Badge or Trailmix **/
        @AuraEnabled public String Name;
        /** Status of the current assignment **/
        @AuraEnabled public String Status;
        /** Due Date for the assignment **/
        @AuraEnabled public DateTime DueDate;
        /** # Days until Due **/
        @AuraEnabled public Integer NumDaysUntilDue;
        /** URL of the Badge or Trailmix **/
        @AuraEnabled public String URL;
        /** Icon of the Badge or Trailmix **/
        @AuraEnabled public String Icon;
        /** Type of Entry (i.e. Badge or Trailmix) **/
        @AuraEnabled public String EntryType;
        
        /**
         * Generic constructor
         * @deprecated - used only for testing
         **/
        public TrailheadEntry (String i, String n, String s, DateTime d, String u, String c, String e ){
            Id = i;
            Name = n;
            Status = s;
            DueDate = d;
            URL = u;
			Icon = c;
            EntryType = e;
        }
        
        /**
         * Constructor consuming a Trailmix Assignment
         **/
        public TrailheadEntry(trailheadapp__User_Trailmix__c uT){
            this.Id = uT.Id;
            this.Name = uT.trailheadapp__Trailmix__r.Name;
            this.Status = uT.trailheadapp__Status__c;
            this.DueDate = uT.trailheadapp__Due_At__c;
            this.URL = uT.trailheadapp__Trailmix__r.trailheadapp__URL__c;
            this.Icon = Label.th_trailhead_trail_icon;
            this.EntryType = Label.th_TrailheadTypeTrailmix;
        }
        
        /**
         * Constructor consuming a Badge Assignment
         **/
        public TrailheadEntry(trailheadapp__User_Badge__c uB){
            this.Id = uB.Id;
            this.Name = uB.trailheadapp__Badge__r.Name;
            this.Status = uB.trailheadapp__Status__c;
            this.DueDate = uB.trailheadapp__Due_Date__c;
            this.URL = uB.trailheadapp__URL__c;
            this.Icon = uB.trailheadapp__Badge__r.trailheadapp__Icon__c;
            this.EntryType = Label.th_TrailheadTypeBadge;
        }

        /**
         * Calculate the number of days until the assignment is due
         * @return Integer
         **/
        private Integer calculateDaysUntilDue(Date targetDate){
            Integer results = 0;
            if (targetDate == null){
                targetDate = Date.today();
            }
            if (this.DueDate != null){
                results = targetDate.daysBetween(this.DueDate.date());
            }
            this.NumDaysUntilDue = results;
            return results;
        }
        
        
        /**
         * Comparison method to allow collated sorting
         * @see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_comparable.htm
         * @param compareTo (Object)
         * @return Integer
         **/
        global Integer compareTo(Object compareTo) {
            TrailheadEntry compareToE = (TrailheadEntry)compareTo;
            if (DueDate == compareToE.DueDate) return 0;
            if (DueDate > compareToE.DueDate || (DueDate == null && compareToE.DueDate != null)) return 1;
            return -1;        
        }
    }
    
    
    
    
    
    //-- #  #   #   #   #   #   #   #   #   #   #   #   #   #   #   #   #
    //-- Aura Enabled methods
    //-- #  #   #   #   #   #   #   #   #   #   #   #   #   #   #   #   #

    
    /**
     *  Determines the collated collection of Badges and TrailMixes associated to the user.
     *  @param whichType (String [TYPE_BADGE|TYPE_TRAILMIX|TYPE_BOTH]) - the type of assignments to count.
     *  @return TrailheadEntry[] - collection of generalized Badges and TrailMixes
     **/
    @AuraEnabled(cacheable=true)
    public static TrailheadEntry[] getAllAssignedTrailEntries(string whichType) {
        TrailheadEntry[] results = new TrailheadEntry[]{};
        
        //-- group and trim if both are included.
        if(whichType == Label.th_TrailheadTypeBoth){
            
            //-- ignore the offset and pageSize because of sorting.
            trailheadapp__User_Trailmix__c[] assignedT = getAssignedTrails(NO_OFFSET, MAX_RESULTS);
            for(trailheadapp__User_Trailmix__c uT : assignedT ){
                TrailheadEntry entry= new TrailheadEntry(uT);
                results.add(entry);
            }
            
            trailheadapp__User_Badge__c[] assignedB = getAssignedBadges(NO_OFFSET,  MAX_RESULTS);
            for(trailheadapp__User_Badge__c uB : assignedB ){           
                TrailheadEntry entry= new TrailheadEntry(uB);
                results.add(entry);
            }
            
            results.sort();
            
        } else if(whichType == Label.th_TrailheadTypeTrailmix){
            trailheadapp__User_Trailmix__c[] assignedT = getAssignedTrails(NO_OFFSET, MAX_RESULTS);
            for(trailheadapp__User_Trailmix__c uT : assignedT ){
                TrailheadEntry entry= new TrailheadEntry(uT);
                results.add(entry);
            }
        } else if(whichType == Label.th_TrailheadTypeBadge){
            trailheadapp__User_Badge__c[] assignedB = getAssignedBadges(NO_OFFSET, MAX_RESULTS);
            for(trailheadapp__User_Badge__c uB : assignedB ){           
                TrailheadEntry entry= new TrailheadEntry(uB);
                results.add(entry);
            }
        } else {
            System.assert(false, 'Unknown type of entry:' + whichType + '. Expecting one of the following [' +
                Label.th_TrailheadTypeBoth + ',' + Label.th_TrailheadTypeTrailmix + ',' + Label.th_TrailheadTypeBadge +
                ']'
            );
        }

        //-- assign due dates
        Date today = Date.today();
        for (TrailheadEntry entryToInitialize : results){
            entryToInitialize.calculateDaysUntilDue(today);
        }
        
        //-- test no results
        //results.clear();
        
        return results;
    }
    




    //-- #  #   #   #   #   #   #   #   #   #   #   #   #   #   #   #   #
    //-- private methods
    //-- #  #   #   #   #   #   #   #   #   #   #   #   #   #   #   #   #
    
    
    
    
	/**
	 * Determines the current set of badges assigned to the current user.
	 * @param rowOffset (Integer) - the number of badges to skip for the current user (pagination)
	 * @param pageSize (Integer) - the number of records to return
	 * @return trailheadapp__User_Badge__c[] - collection of userBadge assignments for the user
	 **/
	 private static trailheadapp__User_Badge__c[] getAssignedBadges(integer rowOffset, integer pageSize) {
        
        //-- @KLUDGE / @TODO: revisit if valueOf is still needed
        //-- please see https://salesforce.stackexchange.com/questions/108355/limit-expression-must-be-of-type-integer-error-when-using-apex-variable-in-soq
        
        pageSize = Integer.valueOf(pageSize);
        rowOffset = Integer.valueOf(rowOffset);

        Id userId = UserInfo.getUserId();
        
        return [SELECT Id, trailheadapp__Badge__c, trailheadapp__Badge__r.trailheadapp__Icon__c,trailheadapp__Badge__r.Name, trailheadapp__URL__c, trailheadapp__Due_Date__c , trailheadapp__Status__c, trailheadapp__Badge_Icon__c
            FROM trailheadapp__User_Badge__c
            WHERE trailheadapp__User__c = :userId And trailheadapp__Finished_Date__c = null
            ORDER BY trailheadapp__Due_Date__c ASC NULLS LAST
            LIMIT :pageSize
            OFFSET :rowOffset];
    }
	
	/**
	 * Determines the current set of trailmixes assigned to the current user.
	 * @param rowOffset (Integer) - the number of badges to skip for the current user (pagination)
	 * @param pageSize (Integer) - the number of records to return
	 * @return trailheadapp__User_Trailmix__c[] - collection of Trailmix assignments for the user
	 **/
    private static trailheadapp__User_Trailmix__c[] getAssignedTrails(integer rowOffset, integer pageSize) {
        
        //-- @KLUDGE / @TODO: revisit if valueOf is still needed
        //-- please see https://salesforce.stackexchange.com/questions/108355/limit-expression-must-be-of-type-integer-error-when-using-apex-variable-in-soq
        
        pageSize = Integer.valueOf(pageSize);
        rowOffset = Integer.valueOf(rowOffset);

        Id userId = UserInfo.getUserId();
        
        return [SELECT Id, trailheadapp__Due_At__c, trailheadapp__Trailmix__r.trailheadapp__URL__c, trailheadapp__Trailmix__r.Name, trailheadapp__Status__c
            FROM trailheadapp__User_Trailmix__c
            WHERE trailheadapp__User__c = :UserId And trailheadapp__Completed_At__c = null
            ORDER BY trailheadapp__Due_At__c ASC NULLS LAST
            LIMIT :pageSize
            OFFSET :rowOffset];
    }
}