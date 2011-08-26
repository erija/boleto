class GenerateController < ApplicationController

  FORMATOS_SUPORTADOS={
    :pdf => 'application/pdf',
    :jpg => 'image/jpg',
    :tif => 'image/tiff',
    :png => 'image/png'
  }

  def single
  
    banco = :bradesco
    
    contrato_numero = params['ContratoNumero']
    
    contrato = Contract.find_by_con_chave(contrato_numero)

    dados = contrato.con_param1.split("]]").collect { |s| s[2..-1].split("=") }.inject({}) { |h, a| h[a[0]] = a[1]; h }
    
    @boleto = case banco
    when :itau then Brcobranca::Boleto::Itau.new
    when :bb then  Brcobranca::Boleto::BancoBrasil.new
    when :hsbc then Brcobranca::Boleto::Hsbc.new
    when :real then Brcobranca::Boleto::Real.new
    when :bradesco then Brcobranca::Boleto::Bradesco.new
    when :unibanco then Brcobranca::Boleto::Unibanco.new
    when :caixa then Brcobranca::Boleto::Caixa.new
    end

    @boleto.cedente = dados["Cedente"]
    @boleto.documento_cedente = "12345678912"
    @boleto.sacado = params["SacadoNome"]
    @boleto.sacado_documento = "12345678900"
    @boleto.valor = 1000.00
    @boleto.agencia = dados["Agencia"]
    @boleto.conta_corrente = dados["Conta"]

    case banco
    when :itau
      # ITAU
      # O que diferencia um tipo de boleto de outro, dentro do itáu é o tipo de carteira utilizado.
      @boleto.convenio = "12345"
      @boleto.numero_documento = "102008"
    when :bb
      # BB
      # O que diferencia um tipo de boleto de outro, dentro do Banco do Brasil é a quantidade de dígitos do convênio.
      @boleto.convenio = "1238798"
      @boleto.numero_documento = "7777700168"
    when :hsbc
      # HSBC
      # O que diferencia um tipo de boleto de outro, dentro do HSBC é a quantidade de dígitos do número do documento.
      @boleto.numero_documento = "102008"
    when :unibanco
      # UNIBANCO
      @boleto.convenio = "1238798"
      @boleto.numero_documento = "7777700168"
    when :caixa
      # CAIXA
      @boleto.agencia = "1565"
      @boleto.numero_documento = "123456789123456"
      @boleto.conta_corrente = "0013877"
      @boleto.convenio = "100000"
    else
      @boleto.convenio = "1238798"
      @boleto.numero_documento = "102008"
    end

    @boleto.dias_vencimento = 5
    @boleto.data_documento = "2008-02-01".to_date
    @boleto.instrucao1 = params["Instrucoes"]
    @boleto.sacado_endereco = params["SacadoEndereco"]

    formato=:pdf
    headers['Content-Type']=FORMATOS_SUPORTADOS[formato]
    send_data @boleto.to(formato), :filename => "boleto_#{banco}.#{formato}"

  end
    
end
