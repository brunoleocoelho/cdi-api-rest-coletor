#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} WSRESTFUL OrdemSeparacao
	Servi�o REST para manipula��o de Ordem de separa��o, retornando JSON
	@author 	Bruno Coelho
	@since 		2019-ABR-29
	@type 		class WSRESTFUL
/*/
WSRESTFUL OrdemSeparacao DESCRIPTION 'Servi�o REST para manipula��o de Ordem de separa��o'
    
    WSDATA ordem As String
    WSDATA produto As String

    WSMETHOD GET Produto DESCRIPTION 'Retorna informa��es do produto passado na URL' WSSYNTAX '/OrdemSeparacao/produto/{produto}' PATH 'produto/{produto}'
    WSMETHOD POST Abre DESCRIPTION 'Busca a ordem de separa��o passada na URL, e abre a conferencia' WSSYNTAX '/OrdemSeparacao/abre/{ordem}' PATH '/abre/{ordem}'
    WSMETHOD POST Conferencia DESCRIPTION '' WSSYNTAX '/OrdemSeparacao/conferencia/{ordem}' PATH '/conferencia/{ordem}'
    WSMETHOD POST Encerra DESCRIPTION '' WSSYNTAX '/OrdemSeparacao/encerra/{ordem}' PATH '/encerra/{ordem}'

END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} Method GET Produto
	Recebe o c�digo de produto de uma Ordem de separa��o, valida e retorna informa��es em JSON
	@author 	Bruno Coelho
	@since 		2019-ABR-29
	@type 		method GET
/*/
WSMETHOD GET Produto WSRECEIVE produto WSSERVICE OrdemSeparacao
    Local cProd         := AllTrim(Self:produto)
    Local oDados        := Nil
    Local oProduto      := Nil
    Local cMsgCons      := '_Rest:OrdemSeparacao:Produto_'
    Local cBody         := ''
    Local cErro         := ''
    Local aStatusDesc   := {"ERRO","OK"}
    Local nStatus       := 0
    Local lRetorno      := .T.

    cBody := DecodeUtf8( ::GetContent() )    
    
    If FwJsonDeserialize(cBody, @oDados)

        /* Chamada da User Function do Adriano 
         * U_ItemDeOrdem( Ordem, Produto )
        */
        cErro := U_ItemDeOrdem( oDados:ORDEM, cProd )
        
        If Empty(cErro)

            BeginSql Alias cAlias
                SELECT B1_COD, B1_DESC, B1_UM
                FROM %Table:SB1%
                WHERE B1_FILIAL = %XFilial:SB1%
                    AND B1_COD = %Exp:cProd%
                    AND %NotDel%
            EndSql

            (cAlias)->(DbGoTop())
            Do While .Not. (cAlias)->(EOF())
                oProduto := ProdConferencia():New()
                oProduto:COD  := AllTrim( (cAlias)->(B1_COD) )
                oProduto:DESC := AllTrim( (cAlias)->(B1_DESC) )
                oProduto:UM   := AllTrim( (cAlias)->(B1_UM) )
                EXIT
            EndDo

            nStatus := 2 //ok
            cJson := FWJsonSerialize(oProduto, .F., .F.)
            
        Else
            nStatus := 1 //erro
            cJson := FWJsonSerialize(cErro, .F., .F.)
        EndIf

    Else
        nStatus := 1 //erro
        cErro := 'N�o foi poss�vel ao verificar a Ordem de Separa��o.')
        cJson := FWJsonSerialize(cErro, .F., .F.)
    EndIf
    
    QOut( DToC(Date()) + Time() + cMsgCons + aStatusDesc[nStatus] +': '+ cJson )
    
    //Montando retorno JSON
    ::SetResponse('{')
    ::SetResponse('{"status":"'+ aStatusDesc[nStatus] +'",')
    If( nStatus == 1, ::SetResponse('"erro":'), ::SetResponse('"produto":') )
    ::SetResponse( EncodeUtf8(cJson) )
    ::SetResponse('}')

Return lRetorno

