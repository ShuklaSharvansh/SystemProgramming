        //header files and extern functions
%{
	#include <string>
    #include <string.h>
	#include <iostream>
	#include "sqlite3.h"
	#include "hsr.tab.h"
	void yyerror (std::string);
	int yyparse (void);
    extern void exchange(char *);
%}
        //grammar for the equation using RegEx
%%
[ \t]+;
"<A"[0-9]+">" { yylval.str_val = yytext; return VARIABLE;}
[0-9][0-9]*(.[0-9]+)? { yylval.double_val = atof ( yytext ); return NUMBER;}
"+" return PLUS;
"-" return MINUS;
"*" return MULTIPLY;
"/" return DIVIDE; 
[\n] return EOL;
"(" return LPAREN;
")" return RPAREN;
%%


void yyerror(std::string str)
{ 
    printf(" Parse Error : \n%s\n", str);
}

int yywrap()
{
    return 1;
}

char *form = new char[30]; //to store formula that is fetched

static int callback(void *data, int argc, char **argv, char **azColName) //callback function for first query
{                                                                       
   form = argv[1];      //storing formula from the fetched row
   YY_BUFFER_STATE buffer = yy_scan_string(form);
   int check = yyparse();
   if(check == 0)
   {
      exchange(form);               //extern function call that exchanges formula terms
   }
   yy_delete_buffer(buffer);
   return 0;
}

int main (int argc, char *argv[])
{
    sqlite3 *db;
    char *zErrMsg = 0;
    int rc;
    std::string sql;
    rc = sqlite3_open("sys_prog.db", &db);          //connection to db
    
    if(rc)
    {
        std::cout << "DB Error: " << sqlite3_errmsg(db);
        sqlite3_close(db);
        return(1);
    }

   char x;
   std::cout<<"\nEnter a formula id: ";
   std::cin>>x;
   sql = "SELECT * FROM 'formulae' where id = ";
   sql.push_back(x);
   sql.push_back(';');
   rc = sqlite3_exec(db, sql.c_str(), callback, 0, &zErrMsg);
   
   sqlite3_close(db);
   return 0;
}