#include "protheus.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} Class UserHandHeld 
    Classe que modela um usuario do coletor de dados Android
    @author     Bruno Coelho
    @since      2019-ABR-26
    @type       Classe
/*/
Class UserHandHeld 
	//propriedades da classe
    Data id	  	        As String
	Data usrName		As String
    Data nome           As String
    Data dtVald         As String
    Data diasExpira     As Integer
    Data depto          As String
    Data cargo          As String
    Data email          As String
    Data bloqueio       As Boolean
    Data nivelAcesso    As Integer

    //metodos da classe
    Method New() Constructor
EndClass

Method New() Class UserHandHeld
Return Self


// 