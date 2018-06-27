public class FileSetupUtil {
    private static final String CLASS_NAME = 'FileSetupUtil';

    public static final String FILE_NAME_DET_METHOD_PREDEFINED             = 'Predefined';
    public static final String FILE_NAME_DET_METHOD_PREDEFINED_PLACEHOLDER = 'PredefinedPlaceholder';
    public static final String FILE_NAME_DET_METHOD_CUSTOM                 = 'Custom';

    //public static final String PREDEFINED_FILE_NAME_SEG_BRANCH = '[BRCH]';
    //public static final String PREDEFINED_FILE_NAME_SEG_FIXED = '[FVAL]';
    //public static final String PREDEFINED_FILE_NAME_SEG_DATETIME = '[PCDT]';
    
    //public static final String SEGMENT_SEPARATOR_WHITE_SPACE = 'White Space';
    //public static final String SEGMENT_SEPARATOR_HYPHEN = 'Hyphen ( - )'; // default
    //public static final String SEGMENT_SEPARATOR_DOT = 'Dot ( . )';
    //public static final String SEGMENT_SEPARATOR_COLON = 'Colon ( : )';
    //public static final String SEGMENT_SEPARATOR_UNDERSCORE = 'Underscore ( _ )';

    /*
    public static List<SelectOption> getFileNameSegmentSelectList() {
        List<SelectOption> fileNameSegmentSelectList = new List<SelectOption>();
        fileNameSegmentSelectList.add(new SelectOption('', Label.List_Option_Select_Value));
        fileNameSegmentSelectList.add(new SelectOption(PREDEFINED_FILE_NAME_SEG_BRANCH, Label.Predefined_File_Name_Segment_Branch_Code));
        fileNameSegmentSelectList.add(new SelectOption(PREDEFINED_FILE_NAME_SEG_FIXED, Label.Predefined_File_Name_Segment_Fixed_Value));
        fileNameSegmentSelectList.add(new SelectOption(PREDEFINED_FILE_NAME_SEG_DATETIME, Label.Predefined_File_Name_Segment_Processing_Datetime));
        return fileNameSegmentSelectList;
    }
    */
    
    /*
    public static String getSegmentSeparatorSymbol(String pFileNameSegmentSeparator){
        Map<String,String> segmentSeparatorMap = TypeUtil.getSeparatorMap();
        String segmentSeparatorSymbol = Constants.HYPHEN; //default separator is Hyphen '-'

        //extract the symbol label
        if (String.IsNotBlank(pFileNameSegmentSeparator)){
            String segmentSeparatorLabel = pFileNameSegmentSeparator.substringBefore('(').trim();
            //get the symbol character from map
            if (segmentSeparatorMap.containsKey(segmentSeparatorLabel)){
                segmentSeparatorSymbol = segmentSeparatorMap.get(segmentSeparatorLabel);
            }
        }
        return segmentSeparatorSymbol;
    }
    */
    
    /*
    public static Map<Integer,String> getFileNameSegmentMap(String pFileName
                                                          , String pSegmentSeparator){
        String segmentSeparatorSymbol = getSegmentSeparatorSymbol(pSegmentSeparator);

        String[] segmentValues;
        if (segmentSeparatorSymbol.equals(Constants.DOT)){
            segmentValues = pFileName.replace(Constants.DOT,'#').split('#');
        } else {
            segmentValues = pFileName.split(segmentSeparatorSymbol);
        }

        Map<Integer,String> fileNameSegmentValueMap = new Map<Integer, String>();
        Integer segmentNumber = 1;

        for (String segmentVal : segmentValues){
            fileNameSegmentValueMap.put(segmentNumber, segmentVal.trim());
            segmentNumber += 1;
        }
        return fileNameSegmentValueMap;
    }
    */
    
    public static String getFileName(File_Setup__c pFileSetup){
        return getFileName(pFileSetup, System.Today());
    }
    public static String getFileName(File_Setup__c pFileSetup, Date pBusinessDate){
        String fileName = Constants.BLANK_STRING;
        if (String.IsBlank(pFileSetup.File_Name_Determination_Method__c)) return null;
        
        //set the file name using predefined name format
        if (pFileSetup.File_Name_Determination_Method__c.equalsIgnoreCase(FILE_NAME_DET_METHOD_PREDEFINED)){
            fileName = pFileSetup.Predefined_Name_Format__c;
        }
        //set the file name using predefined name format and placeholder
        else if (pFileSetup.File_Name_Determination_Method__c.equalsIgnoreCase(FILE_NAME_DET_METHOD_PREDEFINED_PLACEHOLDER)){
            fileName = pFileSetup.Predefined_Name_Format__c;
            //TO DO add logic to replace the place holder in the file name using placeholder value
        }
        //get the file name from custom class
        else if (pFileSetup.File_Name_Determination_Method__c.equalsIgnoreCase(FILE_NAME_DET_METHOD_CUSTOM)){
            if (String.IsNotBlank(pFileSetup.Custom_Class_Name__c)){
                Type fileNameBuilderType = TypeUtil.getCustomClassType(pFileSetup.Custom_Class_Name__c);
                
                if(fileNameBuilderType != null) {
                    FileNameBuilder fileNameBdlr = (FileNameBuilder) fileNameBuilderType.newInstance();
                    fileName = (fileNameBdlr != null) ? fileNameBdlr.getFileName() : Constants.BLANK_STRING;
                }
            }
        }        

        //Assumption : Predefined Name format and the name returned by the custom class does not include extension
        if(String.isNotBlank(pFileSetup.File_Extension__c)) {
            fileName += Constants.DOT + pFileSetup.File_Extension__c;
        }
        return fileName;
    }
    
    /*
     * Method to return the file setup record with or without segments
     * @param - pFileSetupCode      : Unique code of the File Setup
     * @param - pWithSegments       : Pass true to get File Setup record
     *                                with segment related list, else false
     */
    public static File_Setup__c getFileSetup(String pFileSetupCode, Boolean pWithSegments){
        return getFileSetupMap(new Set<String>{pFileSetupCode}, pWithSegments).get(pFileSetupCode);
    }
    public static Map<String, File_Setup__c> getFileSetupMap(Set<String> pFileSetupCodes, Boolean pWithSegments){
        DynamicQueryBuilder fileSetupQuery = DynamicQueryFactory.createQuery(Schema.SObjectType.File_Setup__c.getName())
                                                  .addFields()
                                                  .addWhereConditionWithBind(1,'File_Setup_Code__c','IN','pFileSetupCodes')
                                                  .addWhereConditionWithValue(2,'Is_Active__c','=',true);

        if (pWithSegments){
            DynamicQueryBuilder segmentSubQuery = DynamicQueryFactory.createSubQuery(Schema.SObjectType.File_Segment_Setup__c.getName(), 'File_Segment_Setup__r')
                                                          .addFields()
                                                          .addWhereConditionWithValue(1,'Is_Active__c','=',true);
            fileSetupQuery.addSubQuery(segmentSubQuery);
        }

        List<File_Setup__c> fileSetupList = (List<File_Setup__c>)Database.query(fileSetupQuery.getQueryString());
        //[SELECT Id, Name, File_Setup_Code__c
        //      , Delimiter__c
        //      , Custom_Class_Name__c
        //      , Datetime_Format__c
        //      , Description__c
        //      , File_Extension__c
        //      , File_Format_Type__c
        //      , File_Name_Determination_Method__c
        //      , File_Segment_Count__c
        //      , File_Maximum_Records__c //FOR FUTURE USE
        //      , Line_Terminator__c
        //      , Maximum_Elements_Used__c
        //      , Placeholder_Type__c
        //      , Predefined_Name_Format__c
        //   FROM File_Setup__c
        //  WHERE File_Setup_Code__c IN :pFileSetupCodes
        //    AND Is_Active__c = true];
        
        Map<String, File_Setup__c> fileSetupMapByCodes = new Map<String, File_Setup__c>();
        
        for (File_Setup__c fileSetup : fileSetupList){
            fileSetupMapByCodes.put(fileSetup.File_Setup_Code__c, fileSetup);
        }
        
        return fileSetupMapByCodes;
    }
    
    /*
     * Method to return segment code to segment record map for the input list of segments
     */
    public static Map<String, File_Segment_Setup__c> getSegmentsMap(List<File_Segment_Setup__c> pFileSegments){
        Map<String, File_Segment_Setup__c> segmentsMap = new Map<String, File_Segment_Setup__c>();
        
        for (File_Segment_Setup__c segment : pFileSegments){
            segmentsMap.put(segment.Segment_Code__c, segment);
        }
        
        return segmentsMap;
    }

    /*
     * Method to get segment code to its elements map
     */
    public static Map<String, Map<Integer, File_Segment_Element_Setup__c>> getSegmentElements(Set<String> pSegmentCodes){

        DynamicQueryBuilder elementSetupQuery = DynamicQueryFactory.createQuery(Schema.SObjectType.File_Segment_Element_Setup__c.getName())
                                                  .addFields()
                                                  .addWhereConditionWithBind(1,'Segment_Code__c','IN','pSegmentCodes')
                                                  .addWhereConditionWithValue(2,'Is_Active__c','=',true)
                                                  .addOrderByField('Segment_Code__c')
                                                  .addOrderByField('Element_Position__c');

        List<File_Segment_Element_Setup__c> allSegmentElements = (List<File_Segment_Element_Setup__c>)Database.query(elementSetupQuery.getQueryString());
        
        Map<String, Map<Integer, File_Segment_Element_Setup__c>> segmentElementsMap = new Map<String, Map<Integer, File_Segment_Element_Setup__c>>();
        
        for (File_Segment_Element_Setup__c element : allSegmentElements){
            Map<Integer, File_Segment_Element_Setup__c> elementsMap = new Map<Integer, File_Segment_Element_Setup__c>();
            
            if (segmentElementsMap.containsKey(element.Segment_Code__c)){
                elementsMap = segmentElementsMap.get(element.Segment_Code__c);
            }
            
            elementsMap.put((Integer)element.Element_Position__c, element);
            segmentElementsMap.put(element.Segment_Code__c, elementsMap);
        }
        
        return segmentElementsMap;
    }
}
