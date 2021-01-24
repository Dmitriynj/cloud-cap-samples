//  
// All stuff below might be useful in the future.
// Only a few slight grammars comes from next rules
// It based on original odata construction rules.
// Original rules - http://docs.oasis-open.org/odata/odata/v4.0/errata03/os/complete/abnf/odata-abnf-construction-rules.txt
// Be careful, possible misspelling when transformed from original 
// rules.
//
//
//
// ---------- Expressions ----------
// ---------- 
boolCommonExpr = ( boolMethodCallExpr /
                 commonExpr /
				 notExpr /
                 ( eqExpr 
                   / neExpr 
                   / ltExpr  
                   / leExpr  
                   / gtExpr 
                   / geExpr 
                   / hasExpr 
                 )?
                 boolParenExpr )
                 ( andExpr / orExpr )?
                 
commonExpr = primitiveLiteral /
			 // parameterAlias /
             // arrayOrObject /
             // rootExpr /
             firstMemberExpr /
             // negateExpr /
             methodCallExpr

boolMethodCallExpr = 
                    "contains" containsFunc /
				     "endswith" endswithFunc /
                     "startwith" startswithFunc
             
methodCallExpr = 
		"length" lengthExpr /
        "indexof" indexofExpr /
        "substring" substringExpr /
        "tolower" tolowerExpr /
        "toupper" toupperExpr /
        "trim" trimExpr 
             
firstMemberExpr = memberExpr
                / inscopeVariableExpr ( "/" memberExpr )?
                
memberExpr = ( qualifiedEntityTypeName "/" )?
             ( propertyPathExpr
             / boundFunctionExpr 
             )
propertyPathExpr = ( entityColNavigationProperty ( collectionNavigationExpr )? 
                   / entityNavigationProperty    ( singleNavigationExpr )?
                   / complexColProperty          ( complexColPathExpr )?
                   / complexProperty             ( complexPathExpr )? 
                   / primitiveColProperty        ( collectionPathExpr )?
                   / primitiveProperty           ( primitivePathExpr )?
                   / streamProperty              ( primitivePathExpr )?
                   )
boundFunctionExpr = functionExpr // boundFunction segments can only be composed if the type of the    
                                 // previous segment matches the type of the first function parameter
collectionNavigationExpr = ( "/" qualifiedEntityTypeName )?
                           ( keyPredicate ( singleNavigationExpr )? 
                           / collectionPathExpr 
                           )?

keyPredicate     = simpleKey / compoundKey // keyPathSegments
simpleKey        = OPEN ( parameterAlias / keyPropertyValue ) CLOSE
compoundKey      = OPEN keyValuePair *( COMMA keyValuePair ) CLOSE
keyValuePair     = ( primitiveKeyProperty / keyPropertyAlias  ) EQ ( parameterAlias / keyPropertyValue )
keyPropertyValue = primitiveLiteral
keyPropertyAlias = odataIdentifier

singleNavigationExpr = "/" memberExpr

complexColPathExpr = ( "/" qualifiedComplexTypeName )?
                     ( collectionPathExpr )?
 
collectionPathExpr = count 
                   / "/" boundFunctionExpr
                   / "/" anyExpr
                   / "/" allExpr
 
complexPathExpr = ( "/" qualifiedComplexTypeName )?
                  ( "/" propertyPathExpr 
                  / "/" boundFunctionExpr 
                  )?

primitivePathExpr = "/" boundFunctionExpr

parameterValue = // arrayOrObject /
                    commonExpr

functionExpr = namespace "."
               ( entityColFunction    functionExprParameters ( collectionNavigationExpr )? 
               / entityFunction       functionExprParameters ( singleNavigationExpr )?
               / complexColFunction   functionExprParameters ( complexColPathExpr )?
               / complexFunction      functionExprParameters ( complexPathExpr )? 
               / primitiveColFunction functionExprParameters ( collectionPathExpr )? 
               / primitiveFunction    functionExprParameters ( primitivePathExpr )? 
               )     
functionExprParameters = OPEN ( functionExprParameter ( COMMA functionExprParameter )* )? CLOSE
functionExprParameter  = parameterName EQ ( parameterAlias / parameterValue )               
                                 
anyExpr = 'any' OPEN WS ( lambdaVariableExpr WS COLON WS lambdaPredicateExpr )? WS CLOSE   
allExpr = 'all' OPEN WS   lambdaVariableExpr WS COLON WS lambdaPredicateExpr   WS CLOSE
lambdaPredicateExpr = boolCommonExpr //; containing at least one lambdaVariableExpr

inscopeVariableExpr  = implicitVariableExpr 
                     / lambdaVariableExpr // only allowed inside a lambdaPredicateExpr
implicitVariableExpr = '$it'              // references the unnamed outer variable of the query
lambdaVariableExpr   = odataIdentifier
                 
notExpr = 'not' RWS boolCommonExpr

andExpr = RWS 'and' RWS boolCommonExpr
orExpr  = RWS 'or'  RWS boolCommonExpr

eqExpr = RWS 'eq' RWS commonExpr     
neExpr = RWS 'ne' RWS commonExpr
ltExpr = RWS 'lt' RWS commonExpr
leExpr = RWS 'le' RWS commonExpr
gtExpr = RWS 'gt' RWS commonExpr
geExpr = RWS 'ge' RWS commonExpr

hasExpr = RWS 'has' RWS enum

boolParenExpr = OPEN WS boolCommonExpr WS CLOSE
parenExpr     = OPEN WS commonExpr     WS CLOSE

negateExpr = "-" WS commonExpr

containsMethodCallExpr   = 'contains'   OPEN WS commonExpr WS COMMA WS commonExpr WS CLOSE

 
// ---------- Names and identifiers ----------
// ----------
    
qualifiedEntityTypeName = namespace "." entityTypeName
qualifiedComplexTypeName    = namespace "." complexTypeName
qualifiedTypeDefinitionName = namespace "." typeDefinitionName 


navigationProperty          = entityNavigationProperty / entityColNavigationProperty  
entityNavigationProperty    = odataIdentifier
entityColNavigationProperty = odataIdentifier

primitiveProperty       = primitiveKeyProperty / primitiveNonKeyProperty
primitiveKeyProperty    = odataIdentifier
primitiveNonKeyProperty = odataIdentifier
primitiveColProperty    = odataIdentifier
complexProperty         = odataIdentifier
complexColProperty      = odataIdentifier
streamProperty          = odataIdentifier

entityFunction       = odataIdentifier
entityColFunction    = odataIdentifier
complexFunction      = odataIdentifier
complexColFunction   = odataIdentifier
primitiveFunction    = odataIdentifier
primitiveColFunction = odataIdentifier

entityTypeName      = odataIdentifier
complexTypeName     = odataIdentifier
typeDefinitionName  = odataIdentifier 
termName            = odataIdentifier


entityFunctionImport       = odataIdentifier
entityColFunctionImport    = odataIdentifier
complexFunctionImport      = odataIdentifier
complexColFunctionImport   = odataIdentifier
primitiveFunctionImport    = odataIdentifier
primitiveColFunctionImport = odataIdentifier

parameterName      = odataIdentifier

// Note: this pattern is overly restrictive, the normative definition is type TSimpleIdentifier in OData EDM XML Schema
// contains 0-127 identifierCharacter-s
odataIdentifier             = identifierLeadingCharacter  (
	identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter? identifierCharacter?
    identifierCharacter? identifierCharacter?
								)
identifierLeadingCharacter  = ALPHA / "_"         // plus Unicode characters from the categories L or Nl
identifierCharacter         = ALPHA / "_" / DIGIT // plus Unicode characters from the categories L, Nl, Nd, Mn, Mc, Pc, or Cf

 
// ---------- Literal Data Values ----------
// ----------

primitiveLiteral = nullValue                  // plain values up to int64Value
                 / booleanValue 
                 / guidValue 
                 / dateValue
                 / dateTimeOffsetValue 
                 / timeOfDayValue
                 / decimalValue 
                 / doubleValue 
                 / singleValue 
                 / sbyteValue 
                 / byteValue
                 / int16Value 
                 / int32Value 
                 / int64Value 
                 / string                     // single-quoted
                 / duration                   // all others are quoted and prefixed
                 / binary 
                 / enum
                 // geographical literals needed

nullValue = 'null' 
booleanValue = "true" / "false"
guidValue = HEXDIG HEXDIG HEXDIG HEXDIG HEXDIG HEXDIG HEXDIG HEXDIG "-"
		    HEXDIG HEXDIG HEXDIG HEXDIG "-" HEXDIG HEXDIG HEXDIG HEXDIG "-"
            HEXDIG HEXDIG HEXDIG HEXDIG "-" 
            HEXDIG HEXDIG HEXDIG HEXDIG
            HEXDIG HEXDIG HEXDIG HEXDIG
            HEXDIG HEXDIG HEXDIG HEXDIG

oneToNine = "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9"    
month = "0" oneToNine
      / "1" ( "0" / "1" / "2" )
day   = "0" oneToNine
      / ( "1" / "2" ) DIGIT
      / "3" ( "0" / "1" )
hour   = ( "0" / "1" ) DIGIT
       / "2" ( "0" / "1" / "2" / "3" ) 
minute = zeroToFiftyNine
second = zeroToFiftyNine 
year  = "-"? ( "0" DIGIT DIGIT DIGIT / oneToNine DIGIT DIGIT DIGIT )
dateValue = year "-" month "-" day

zeroToFiftyNine = ( "0" / "1" / "2" / "3" / "4" / "5" ) DIGIT
fractionalSeconds = DIGIT DIGIT? DIGIT? DIGIT?
					DIGIT? DIGIT? DIGIT? DIGIT?
                    DIGIT? DIGIT? DIGIT? DIGIT?
dateTimeOffsetValue = year "-" month "-" day "T" hour ":" minute ( ":" second ( "." fractionalSeconds )? )? ( "Z" / SIGN hour ":" minute )
timeOfDayValue = hour ":" minute ( ":" second ( "." fractionalSeconds )? )?
decimalValue = SIGN? DIGIT+ ("." DIGIT+)?
nanInfinity = 'NaN' / '-INF' / 'INF'

doubleValue = decimalValue ( "e" SIGN? DIGIT+ )? / nanInfinity // IEEE 754 binary64 floating-point number (15-17 decimal digits)
singleValue = doubleValue  									   // IEEE 754 binary32 floating-point number (6-9 decimal digits)
byteValue  = DIGIT DIGIT? DIGIT?           // numbers in the range from 0 to 255
sbyteValue = SIGN? DIGIT DIGIT? DIGIT?  // numbers in the range from -128 to 127
// numbers in the range from -32768 to 32767 
// contains 1-5 digits
int16Value = SIGN? DIGIT DIGIT? DIGIT? DIGIT? DIGIT?
// numbers in the range from -2147483648 to 2147483647
// contains 1-15 digits
int32Value = SIGN? DIGIT DIGIT? DIGIT? DIGIT? DIGIT?
				   DIGIT? DIGIT? DIGIT? DIGIT? DIGIT?
                   DIGIT? DIGIT? DIGIT? DIGIT? DIGIT?
// numbers in the range from -9223372036854775808 to 9223372036854775807        
// contains 1-19 digits
int64Value = SIGN? DIGIT DIGIT? DIGIT? DIGIT? DIGIT? DIGIT? DIGIT? DIGIT? 
				   DIGIT? DIGIT? DIGIT? DIGIT? DIGIT? DIGIT? DIGIT? DIGIT?
                   DIGIT? DIGIT? DIGIT? 

string "string literal" = SQUOTE strEntireVal SQUOTE // single-quoted

duration      = "duration" SQUOTE durationValue SQUOTE
durationValue = SIGN? "P" ( DIGIT+ "D") ? ( "T" ( DIGIT+ "H" )? ( DIGIT+ "M" )? ( DIGIT+ ( "." DIGIT+ )? "S" )? )?
     // the above is an approximation of the rules for an xml dayTimeDuration.
     // see the lexical representation for dayTimeDuration in http://www.w3.org/TR/xmlschema11-2#dayTimeDuration for more information
binary      = "binary" SQUOTE binaryValue SQUOTE
binaryValue = (base64char base64char base64char base64char)* ( base64b16  / base64b8 )?
base64b16   = base64char base64char ( 'A' / 'E' / 'I' / 'M' / 'Q' / 'U' / 'Y' / 'c' / 'g' / 'k' / 'o' / 's' / 'w' / '0' / '4' / '8' )    "="? 
base64b8    = base64char ( 'A' / 'Q' / 'g' / 'w' ) ( "==" )?
base64char  = ALPHA / DIGIT / "-" / "_"

enumerationMember = odataIdentifier
enumerationTypeName = odataIdentifier

enumValue       = singleEnumValue ( COMMA singleEnumValue )*

singleEnumValue = enumerationMember / enumMemberValue
enumMemberValue = int64Value

enum = qualifiedEnumTypeName SQUOTE enumValue SQUOTE
qualifiedEnumTypeName = namespace "." enumerationTypeName

// an alias is just a single-part namespace
namespace     = namespacePart ( "." namespacePart )*
namespacePart = odataIdentifier


// ---------- URI syntax ----------
// ----------
otherDelims   = "!" / "(" / ")" / "*" / "+" / "," / ";"
unreserved = [A-Za-z] / [0-9] / " " / "-" / "." / "_" / "~"
pcharNoSQUOTE = unreserved / otherDelims / "$" / "&" / "=" / ":" / "@"
SQUOTEInString = SQUOTE SQUOTE // two consecutive single quotes represent one within a string literal
parameterAlias = AT odataIdentifier

//   
// ---------- Punctuation ----------
//

WS "whitespace" = ( SP / HTAB )*  

AT     = "@" 
COLON  = ":" 
COMMA  = "," 
EQ     = "="
SIGN   = "+" / "-"
SEMI   = ";" 
STAR   = "*" 
SQUOTE = "'"
OPEN  = "(" 
CLOSE = ")" 


//   
// ---------- ABNF core definitions ----------
//

ALPHA "letter" = [A-Za-z] 
AtoF "A to F" = "A" / "B" / "C" / "D" / "E" / "F" 
DIGIT "digit" = [0-9] 
HEXDIG "hexing" = DIGIT / AtoF 
DQUOTE "double quote" = '"'
SP "space" = ' ' 
HTAB "horizontal tab" = '	' 
WSP "white space" = SP / HTAB 
//LWSP = (WSP / CRLF WSP)* 
//VCHAR "visible printing characters" = %x21-7E 
//CHAR = %x01-7F
//;LOCTET = %x00-FF 
//;CR     = %x0D 
//;LF     = %x0A 
//;CRLF   = CR LF
BIT = "0" / "1" 
RWS = ( SP / HTAB )+  // "required" whitespace 


//-- Whitespaces
_ "one or more whitespaces" = $[ \t\n]+ 
o "optional whitespaces" = $[ \t\n]* 