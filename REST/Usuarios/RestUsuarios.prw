#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

#DEFINE CRLF Chr(13)+Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} WSRESTFUL LoginUser
	Serviço REST para login de usuários no Protheus, retornando JSON
	@author 	Bruno Coelho
	@since 		2019-ABR-26
	@type 		class WSRESTFUL
/*/
WSRESTFUL LoginUser DESCRIPTION "Serviço REST para manipulação de usuarios/vendedores"
	WSDATA usr As String 	//String de Usuário via URL

	WSMETHOD GET DESCRIPTION "Recebe o usuário do coletor na URL retornando informações do mesmo" WSSYNTAX "/LoginUser/{usr}" PATH "/{usr}"
 END WSRESTFUL


//Metodos Implementação
//-------------------------------------------------------------------
/*/{Protheus.doc} Method GET
	Recebe o usuário na URL retornando informações do mesmo (JSON)
	@author 	Bruno Coelho
	@since 		2019-ABR-26
	@type 		class WSRESTFUL
    @see        PswRet(): http://tdn.totvs.com/pages/releaseview.action?pageId=267792734
/*/
WSMETHOD GET WSRECEIVE usr WSSERVICE LoginUser
	Local cUsr          := Self:usr
	Local cMsgCon       := "_Rest:LoginUser_"
	Local cJson         := ""
	Local cBody         := ""
	Local aUser         := {}
	Local aErros        := {}
    Local aStatusDesc	:= {"ERRO", "OK"}
    Local nStatus       := 0
	Local oUser         := Nil
	Local lRetorno      := .T.	
	
	::SetContentType("application/json")
        
    // Orders: 1->ID, 2->Nome, 3->Senha, 4->Email	
    PswOrder(2)
    
    If PswSeek( cUsr, .T. )  // Opção: .T.->Usuarios, .F.->Grupos

        aUser := PswRet()
        oUser := UserHandHeld():New()

        oUser:id            := aUser[1][1]
        oUser:usrName       := aUser[1][2]
        oUser:nome          := aUser[1][4]
        oUser:dtVald        := DToC(aUser[1][6]) 
        oUser:diasExpira    := aUser[1][7] 
        oUser:depto         := aUser[1][12]
        oUser:cargo         := aUser[1][13]
        oUser:email         := aUser[1][14]
        oUser:bloqueio      := aUser[1][17]
        oUser:nivelAcesso   := aUser[1][25]

        nStatus := 2 //ok
        cJson := FWJsonSerialize( oUser, .F., .F.)

    Else
        nStatus := 1 //erro
        AAdd( aErros, "Usuario nao encontrado")
        cJson := FWJsonSerialize( aErros, .F., .F.)
    EndIf

    // Escrevendo mensagem no console
    QOut( DToC(Date()) +'_'+ Time() + cMsgCon + aStatusDesc[nStatus] +'_'+ cJson + CRLF )

    // MONTANDO RESPOSTA JSON
    ::SetResponse('{')
    ::SetResponse('"status":"'+ aStatusDesc[nStatus] +'",')
    If( nStatus == 1 , ::SetResponse('"erro":'), ::SetResponse('"usuario":') )
    ::SetResponse( EncodeUtf8(cJson))
    ::SetResponse('}')
    
Return lRetorno	
