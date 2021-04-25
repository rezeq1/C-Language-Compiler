%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol.h"




extern int yylex();
extern int yylineno;
extern char *yytext;

extern Data data;

int yyerror(const char *str);

//char temp[1024];
%}

%union {
  char* string;
  struct Tree* tree;
}


%token  BOOL CHAR VOID INT STRING INTP CHARP 
%token  IF ELSE WHILE DO FOR  RETURN
%token  AND_OP EQ_OP GE_OP LE_OP NE_OP OR_OP
%token  NUL 
%token <string> CONST_STRING ID CONST_INT CONST_CHAR TRUE FALSE

%type <tree> S FUNC FUNCS PAR_LIST BLOCK RETURN_EXP BLOCK_BODY PAR_DEC
%type <tree> DECLERATIONS STATMENTS DECLARE STATMENT IDS_LIST STRING_IDS_LIST
%type <tree>  EXP TYPE_NOSTRING  IDN PARS STRING_TYPE
%type <tree> STRING_INDEX FUNC_CALL CALL_ID_LIST POINTER_DER POINTER_REF UN_MINUS
%type <tree> LHS ASSIGMENT DO_WHILE WHILE_STATMENT FOR_STATMENT STATMENT_NOT_IF IF_STATMENT
%type <tree> MATCHED UNMATCHED FOR_DECLARE

%right '='
%left OR_OP
%left AND_OP
%left EQ_OP NE_OP
%left '>' '<' GE_OP LE_OP
%left '+' '-'
%left '*' '/'
%right '&'
%right '^'

%%
S:FUNCS { data.ast=$1;test();}
 ;
FUNCS:FUNC {$$=$1;}
     | FUNCS FUNC {$$=make2Tree("", Other,$1,$2);}
     ;
FUNC: TYPE_NOSTRING IDN  PAR_LIST  BLOCK  {$$=make4Tree("FUNC",Func,$1,$2,$3,$4);}
     | VOID IDN PAR_LIST  BLOCK  {$$=make4Tree("FUNC",Func,makeLeaf("VOID",Void),$2,$3,$4);}
     ;


TYPE_NOSTRING: INT {$$=makeLeaf("INT",Int);}
     | CHAR {$$=makeLeaf("CHAR",Char);}
     | BOOL {$$=makeLeaf("BOOL",Bool);}
     | INTP {$$=makeLeaf("INTP",Intp);}
     | CHARP {$$=makeLeaf("CHARP",Charp);}
     ;
IDN: ID {$$=makeLeaf($1,Id);$$->lineno=yylineno;}
   ;
STRING_TYPE: STRING {$$=makeLeaf("STRING",String);}
;

PAR_LIST: '(' ')' {$$=makeLeaf("PARAMETERS",Empty);}
        | '(' PARS ')' {$$=$2;}
        ;
        
PARS: PAR_DEC {$$=$1;}
      | PARS ',' PAR_DEC {$$=make2Tree("",Other,$1,$3);}
      ;

PAR_DEC: TYPE_NOSTRING IDN {$$=make2Tree("",Par,$1,$2);}
        ;

BLOCK: '{' '}' {$$=makeLeaf("BLOCK",Empty);}
     | '{' BLOCK_BODY '}' {$$=make1Tree("BLOCK",Block,$2);}
     ;
RETURN_EXP: RETURN EXP ';' {$$=make1Tree("RETURN",Return,$2);}
          | RETURN ';' {$$=makeLeaf("RETURN",Return);}
           ;

 BLOCK_BODY: DECLERATIONS STATMENTS {$$=make2Tree("",Other,$1,$2);}
           | DECLERATIONS {$$=$1;}
           | STATMENTS {$$=$1;}
          ;

DECLERATIONS: DECLARE {$$=$1;}
             | DECLERATIONS DECLARE {$$=make2Tree("",Other,$1,$2);}
             ;

DECLARE: IDS_LIST ';' {$$=make1Tree("DECLARE",Decs,$1);}
        | FUNC {$$=$1;}
        | STRING_IDS_LIST ';' {$$=make1Tree("DECLARE",Decs,$1);}
        ;

STRING_IDS_LIST: STRING_TYPE STRING_INDEX {$$=make2Tree("",Decs,$1,$2);}
                | STRING_IDS_LIST ',' STRING_INDEX {$$=make2Tree("",Decs,$1,$3);}
                ;

STRING_INDEX: IDN '[' EXP ']' {$$=make2Tree("[]",Stringindex,$1,$3);}


;

IDS_LIST: TYPE_NOSTRING IDN {$$=make2Tree("",Other,$1,$2);}
         | IDS_LIST ',' IDN {$$=make2Tree("",Other,$1,$3);}
         ;
        

STATMENTS: STATMENT {$$=$1;}
          | STATMENTS STATMENT {$$=make2Tree("",Other,$1,$2);}
          ;

STATMENT: STATMENT_NOT_IF {$$=$1;}
        | IF_STATMENT {$$=$1;}
        ;

STATMENT_NOT_IF:ASSIGMENT ';' {$$=$1;}
        | FUNC_CALL ';' {$$=$1;}
        | WHILE_STATMENT {$$=$1;}
        | DO_WHILE {$$=$1;}
        | FOR_STATMENT {$$=$1;}
        | BLOCK {$$=$1;}
        | RETURN_EXP {$$=$1;}
        ;

IF_STATMENT: MATCHED {$$=$1;}
          | UNMATCHED {$$=$1;}
;

MATCHED: IF '(' EXP ')' MATCHED ELSE MATCHED {$$=make3Tree("IF-ELSE",If,$3,$5,$7);}
       | STATMENT_NOT_IF {$$=$1;}
       ;

UNMATCHED: IF '(' EXP ')' MATCHED {$$=make2Tree("IF",If,$3,$5);}
         | IF '(' EXP ')' UNMATCHED {$$=make2Tree("IF",If,$3,$5);}
         | IF '(' EXP ')' MATCHED ELSE UNMATCHED {$$=make3Tree("IF-ELSE",If,$3,$5,$7);}
         ;

ASSIGMENT:LHS '=' EXP  {$$=make2Tree("=",Asign,$1,$3);}
;

WHILE_STATMENT: WHILE '(' EXP ')' STATMENT {$$=make2Tree("WHILE",While,$3,$5);}
;

DO_WHILE: DO BLOCK WHILE  '(' EXP ')' ';' {$$=make2Tree("DO-WHILE",Do,$2,$5);}
;

FOR_STATMENT: FOR '(' FOR_DECLARE ';' EXP ';' ASSIGMENT ')' STATMENT  {$$=make4Tree("FOR",For,$3,$5,$7,$9);}
;
FOR_DECLARE: TYPE_NOSTRING IDN '=' EXP {$$=make3Tree("",Other,$1,$2,$4);}
;

LHS: IDN {$$=$1;}
   | POINTER_DER {$$=$1;}
   | STRING_INDEX {$$=$1;}
   ;

EXP: IDN {$$=$1;}
   | CONST_INT {$$=makeLeaf($1,Int);$$->lineno=yylineno;}
   | CONST_CHAR {$$=makeLeaf($1,Char);$$->lineno=yylineno;}
   | CONST_STRING {$$=makeLeaf($1,String);$$->lineno=yylineno;}
   | NUL {$$=makeLeaf("null",Null);}
   | TRUE {$$=makeLeaf("1",Bool);}
   | FALSE {$$=makeLeaf("0",Bool);}
   | STRING_INDEX {$$=$1;}
   | '|' IDN '|' {$$=make1Tree("||",Abs,$2);}
   | EXP AND_OP EXP {$$=make2Tree("AND",Ebool,$1,$3);}
   |EXP OR_OP EXP {$$=make2Tree("OR",Ebool,$1,$3);}
   |EXP EQ_OP EXP {$$=make2Tree("==",Eall2bool,$1,$3);}
   |EXP LE_OP EXP {$$=make2Tree("<=",Eint2bool,$1,$3);}
   |EXP GE_OP EXP {$$=make2Tree(">=",Eint2bool,$1,$3);}
   |EXP '>' EXP {$$=make2Tree(">",Eint2bool,$1,$3);}
   |EXP '<' EXP {$$=make2Tree("<",Eint2bool,$1,$3);}
   |EXP NE_OP EXP {$$=make2Tree("!=",Eall2bool,$1,$3);}
   |EXP '+' EXP {$$=make2Tree("+",Eint,$1,$3);}
   |EXP '-' EXP {$$=make2Tree("-",Eint,$1,$3);}
   |EXP '*' EXP {$$=make2Tree("*",Eint,$1,$3);}
   |EXP '/' EXP {$$=make2Tree("/",Eint,$1,$3);}
   | '(' EXP ')' {$$=$2;}
   | POINTER_DER {$$=$1;}
   | POINTER_REF {$$=$1;}
   | FUNC_CALL {$$=$1;}
   | '!' EXP {$$=make1Tree("!",Not,$2);}
   | UN_MINUS {$$=$1;}
   ;

UN_MINUS: '-' EXP {$$=make1Tree("-", Uminus,$2);}
;
FUNC_CALL: IDN '(' ')' {$$=make1Tree("FUNC CALL",Funccall,$1);}
         | IDN '(' CALL_ID_LIST ')'  {$$=make2Tree("FUNC CALL",Funccall,$1,$3);}
         ;

CALL_ID_LIST: EXP {$$=make1Tree("",Other,$1);}
         | CALL_ID_LIST ',' EXP {$$=make2Tree("",Other,$1,$3);}
         ;

POINTER_DER: '^' IDN {$$=make1Tree("^",Dref,$2);}
;
POINTER_REF:'&' IDN {$$=make1Tree("&",Ref,$2);}
           |'&' STRING_INDEX {$$=make1Tree("&",Ref,$2);}

%%
int yyerror(const char *str)
{
	fprintf(stderr, "%s error , line number: %d\n", str,yylineno);
	fprintf(stderr, "parser caused by: '%s'\n",yytext);
}

int main() {
  yyparse();
  return 0;
}
Tree* make4Tree(char* str,int type, Tree* n1, Tree* n2, Tree* n3, Tree* n4)
{
   Tree *result= (Tree*) malloc (sizeof(Tree));
   result->n1=n1;
    result->n2=n2;
    result->n3=n3;
     result->n4=n4;
     result->type=type;
    result->string=str;
   return result;
}
Tree* make3Tree(char* str,int type, Tree* n1, Tree* n2, Tree* n3)
{
   return make4Tree(str,type,n1,n2,n3,NULL);
}
Tree* make2Tree(char* str,int type, Tree* n1, Tree* n2)
{
    return make4Tree(str,type,n1,n2,NULL,NULL);
}
Tree* make1Tree(char* str,int type, Tree* n1)
{
   return make4Tree(str,type,n1,NULL,NULL,NULL);
}
Tree* makeLeaf(char* str, int type)
{
   return make4Tree(str,type,NULL,NULL,NULL,NULL);
}

void printTree(Tree* t,int offset)
{ 
  int i=0,j;
  if(t->n1!=NULL)i++;
  if(t->n2!=NULL)i++;

  if (i==0)
    printf("%s ",t->string);
  else if (i==1)
  {
       printf("(%s ",t->string);
       printTree(t->n1,offset);
       printf(")");        
  }
  else
  {
      printf("\n");
      for(j=0;j<offset;j++)
      printf("|  ");
      printf("(%s ",t->string);
      printTree(t->n1,offset+1);
      printTree(t->n2,offset+1);
      if(t->n3!=NULL)
          printTree(t->n3,offset+1);
      if(t->n4!=NULL)
          printTree(t->n4,offset+1);
      printf(")\n");
       for(j=0;j<offset-1;j++)
      printf("|  ");
    }
}
void deleteTree(Tree* t)
{
  int i;

  deleteTree(t->n1);
  deleteTree(t->n2);
  deleteTree(t->n3);
  deleteTree(t->n4);
   free(t);
}

