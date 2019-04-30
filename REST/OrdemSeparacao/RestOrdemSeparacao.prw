#INCLUDE 'TOTVS.CH'
#INCLUDE 'RESTFUL.CH'

#DEFINE CRLF Chr(13)+Chr(10)

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

    WSMETHOD GET Produto DESCRIPTION 'Retorna informa��es do produto passado na URL' ;
        WSSYNTAX '/OrdemSeparacao/produto/{produto}' ;
        PATH 'produto/{produto}'
    
    WSMETHOD POST AbreConf DESCRIPTION 'Recebe o c�digo de uma Ordem de separa��o, e abre a conferencia da mesma' ;
        WSSYNTAX '/OrdemSeparacao/abreconf/{ordem}' ;
        PATH '/abreconf/{ordem}'
    
    WSMETHOD POST Conferencia DESCRIPTION 'Recebe um item contado da conferencia de uma ordem de separa��o' ;
        WSSYNTAX '/OrdemSeparacao/conferencia/{ordem}' ;
        PATH '/conferencia/{ordem}'
    
    WSMETHOD POST Encerra DESCRIPTION 'Recebe a ordem de separa��o a ter conferencia encerrada' ;
        WSSYNTAX '/OrdemSeparacao/encerra/{ordem}' ;
        PATH '/encerra/{ordem}'

END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} Method GET Produto
	Recebe o c�digo de uma Ordem de separa��o, e abre a conferencia da mesma 
    Url: /OrdemSeparacao/produto/{produto}
	@author 	Bruno Coelho
	@since 		2019-ABR-29
	@type 		method GET
/*/
WSMETHOD GET Produto WSRECEIVE produto WSSERVICE OrdemSeparacao
    Local cProd         := AllTrim(Self:produto)
    Local oDados        := Nil
    Local oProduto      := Nil
    Local cMsgCons      := '_Rest:OrdemSeparacao:GET:Produto_'
    Local cBody         := ''
    Local cErro         := ''
    Local aStatusDesc   := {"ERRO","OK"}
    Local nStatus       := 0
    Local lRetorno      := .T.

	::SetContentType("application/json")

    cBody := DecodeUtf8( ::GetContent() )
    QOut(cMsgCons +'cBody: '+ cBody) //linha teste
    
    If FwJsonDeserialize(cBody, @oDados)

        /* Chamada da User Function do Adriano 
         * U_XXXXXX( Ordem, Produto )
        */
        cErro := If( FindFunction('U_XXXXXX'), U_XXXXXX( oDados:ORDEM, cProd ), 'Fun��o U_XXXXXX n�o exisente')
        
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
    
    QOut( DToC(Date()) +'_'+ Time() + cMsgCons + aStatusDesc[nStatus] +': '+ cJson + CRLF )
    
    //Montando retorno JSON
    ::SetResponse('{')
    ::SetResponse('"status":"'+ aStatusDesc[nStatus] +'",')
    If( nStatus == 1, ::SetResponse('"erro":'), ::SetResponse('"produto":') )
    ::SetResponse( EncodeUtf8(cJson) )
    ::SetResponse('}')

Return lRetorno


//-------------------------------------------------------------------
/*/{Protheus.doc} Method POST AbreConf
	Busca a ordem de separa��o passada na URL, e abre a conferencia e retorna informa��es em JSON
    Url: /OrdemSeparacao/abreconf/{ordem}
	@author 	Bruno Coelho
	@since 		2019-ABR-30
	@type 		method POST
/*/
WSMETHOD POST AbreConf WSRECEIVE ordem WSSERVICE OrdemSeparacao
    Local cOrdSep       := AllTrim(Self:ordem)
    Local oDados        := Nil
    Local cMsgCons      := '_Rest:OrdemSeparacao:POST:AbreConf_'
    Local cBody         := ''
    Local cErro         := ''
    Local aStatusDesc   := {"ERRO","OK"}
    Local nStatus       := 0
    Local lRetorno      := .T.

	::SetContentType("application/json")

    cBody := DecodeUtf8( ::GetContent() )

    If .Not. Empty(cBody)
        QOut(cMsgCons +'cBody: '+ cBody) //linha teste

        If FwJsonDeserialize(cBody, @oDados)
            /** Chamada da User Function que faz a abertura da conferencia da O.S.
             * U_XXXXXX( cOrdSep )
             */
            cErro := If( FindFunction('U_XXXXXX'), U_XXXXXX( cOrdSep ), 'Fun��o U_XXXXXX n�o exisente')

            If Empty(cErro)
                nStatus := 2 //ok
                cJson := 'Ordem de Separa��o '+ cOrdSep +' aberta'
                cJson := FWJsonSerialize(cJson, .F., .F.)
            Else
                nStatus := 1 //erro
                cJson := FWJsonSerialize(cErro, .T., .T.)
            EndIf
            
        Else
            nStatus := 1 //erro
            cJson := 'Problema com deserializa��o JSON'
            cJson := FWJsonSerialize(cJson, .F., .F.)
        EndIf

    Else
        nStatus := 1 //erro
        cJson := 'N�o encontrado conte�do HTTP para processar'
        cJson := FWJsonSerialize(cJson, .F., .F.)
    EndIf

    QOut( DToC(Date()) +'_'+ Time() + cMsgCons + aStatusDesc[nStatus] +': '+ cJson + CRLF )
    
    //Montando resposta JSOn
    ::SetResponse('{')
    ::SetResponse('"status":"'+ aStatusDesc[nStatus] +'",')
    If( nStatus == 1, ::SetResponse('"erro":'), ::SetResponse('"mensagem":') )
    ::SetResponse( EncodeUtf8(cJson) )
    ::SetResponse('}')

Return lRetorno


//-------------------------------------------------------------------
/*/{Protheus.doc} Method POST Conferencia
	Recebe um item contado da conferencia de uma ordem de separa��o
    Url: /OrdemSeparacao/conferencia/{ordem}
	@author 	Bruno Coelho
	@since 		2019-ABR-30
	@type 		method POST
/*/
WSMETHOD POST Conferencia WSRECEIVE ordem WSSERVICE OrdemSeparacao
    Local cOrdSep       := AllTrim(Self:ordem)
    Local oProduto      := Nil
    Local cMsgCons      := '_Rest:OrdemSeparacao:POST:Conferencia_'
    Local cBody         := ''
    Local cErro         := ''
    Local aStatusDesc   := {"ERRO","OK"}
    Local nStatus       := 0
    Local lRetorno      := .T.

    :SetContentType('application/json')

    cBody := DecodeUtf8( ::GetContent() )

    If .Not. Empty(cBody)
        QOut(cMsgCons +'cBody: '+ cBody) //linha teste
        
        If FwJsonDeserialize(cBody, @oProduto)
            /** Chamada do programa que grava o produto e quantidade lidos para a O.S.
             * U_XXXXXX( cOrdem, cProdCod, nQty )
             */
            cErro := If( FindFunction('U_XXXXXX'), U_XXXXXX( cOrdSep, oProduto:COD, oProduto:QTD ), 'Fun��o U_XXXXXX n�o exisente')

            If Empty(cErro)
                nStatus := 2 //ok
                cJson := 'Produto '+ oProduto:COD +', Qtd '+ AllTrim(cValToChar(oProduto:QTD)) +'O.S. '+ cOrdSep +' conferido.'
                cJson := FWJsonSerialize(cJson, .F., .F.)
            Else
                nStatus := 1 //erro
                cJson := FWJsonSerialize(cErro, .F., .F.)
            EndIf

        Else
            nStatus := 1 //erro
            cJson := 'Problema com deserializa��o JSON'
            cJson := FWJsonSerialize(cJson, .F., .F.)
        EndIf

    Else
        nStatus := 1 //erro
        cJson := 'N�o encontrado conte�do HTTP para processar'
        cJson := FWJsonSerialize(cJson, .F., .F.)
    EndIf

    QOut( DToC(Date()) +'_'+ Time() + cMsgCons + aStatusDesc[nStatus] +': '+ cJson + CRLF )

    //Montagem da resposta JSON
    ::SetResponse('{')
    ::SetResponse('"status":"'+ aStatusDesc[nStatus] +'",')
    If( nStatus == 1, ::SetResponse('"erro":'), ::SetResponse('"mensagem":') )
    ::SetResponse( EncodeUtf8(cJson) )
    ::SetResponse('}')

Return lRetorno


//-------------------------------------------------------------------
/*/{Protheus.doc} Method POST Encerra
	Recebe a ordem de separa��o a ter conferencia encerrada
    Url: /OrdemSeparacao/encerra/{ordem}
	@author 	Bruno Coelho
	@since 		2019-ABR-30
	@type 		method POST
/*/
WSMETHOD POST Encerra WSRECEIVE ordem WSSERVICE OrdemSeparacao
    Local cOrdSep       := AllTrim(Self:ordem)
    Local oProduto      := Nil
    Local cMsgCons      := '_Rest:OrdemSeparacao:POST:Encerra_'
    Local cBody         := ''
    Local cErro         := ''
    Local aStatusDesc   := {"ERRO","OK"}
    Local nStatus       := 0
    Local lRetorno      := .T.

    ::SetContentType('application/json')

    /** Chamada da User Function para encerrar conferencia da O.S.
     * U_XXXXXX( cOrdem )
     */
    cErro := If( FindFunction('U_XXXXXX'), U_XXXXXX( cOrdSep ), 'Fun��o U_XXXXXX n�o exisente')

    If Empty(cErro)
        nStatus := 2 //ok
        cJson := 'Confer�ncia da O.S. '+ cOrdSep +' encerrada'
        cJson := FWJsonSerialize(cJson, .F., .F.)
    Else
        nStatus := 1 //erro
        cJson := FWJsonSerialize(cErro, .F., .F.)
    EndIf

    QOut( DToC(Date()) +'_'+ Time() + cMsgCons + aStatusDesc[nStatus] +': '+ cJson + CRLF )
    
    //Montagem da resposta JSON
    ::SetResponse('{')
    ::SetResponse('"status":"'+ aStatusDesc[nStatus] +'",')
    If( nStatus == 1, ::SetResponse('"erro":'), ::SetResponse('"mensagem":') )
    ::SetResponse( EncodeUtf8(cJson) )
    ::SetResponse('}')

Return lRetorno
