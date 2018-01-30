//Replace Account with the API name of Sobject you want to describe
Schema.DescribeSObjectResult sobjDesc = Schema.SObjectType.Account;
System.debug(loggingLevel.ERROR, 'SObject Label : ' + sobjDesc.getLabel());
System.debug(loggingLevel.ERROR, 'SObject Name : ' + sobjDesc.getName());

//Get the fields of the sobject
Map<String, Schema.SObjectField> fieldMap = sobjDesc.fields.getMap();
System.debug(loggingLevel.ERROR, 'Number of fields : ' + fieldMap.size());
System.debug(loggingLevel.ERROR, 'Fields : ');
System.debug(loggingLevel.ERROR, 'Name,Label,Type');
List<String> fieldList = new List<String>(fieldMap.keySet());
fieldList.sort();

for(String fieldName : fieldList){
    Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();
    System.debug(loggingLevel.ERROR, fieldDesc.getName() + ',' + fieldDesc.getLabel() + ',' + String.valueOf(fieldDesc.getType()));
}
