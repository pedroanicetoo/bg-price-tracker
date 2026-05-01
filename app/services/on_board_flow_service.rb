class OnBoardFlowService
  # encoding: utf-8
  Result = Struct.new(:messages, keyword_init: true)

  def initialize(user:, text:, session_manager: nil)
    @user = user
    @text = text.to_s.strip
  end

  def call
    if @text.match?(CommandTypes::ADD_PATTERN)
      collection_command
    elsif @text.match?(CommandTypes::HELP_PATTERN)
      Result.new(messages: [help_message])
    else
      Result.new(messages: [fallback_message])
    end
  end

  private

  def collection_command
    query = extract_query(@text)
    collection_result(AppendingCollectionService.new(user: @user, query: query).call)
  end

  def collection_result(cmd_result)
    Result.new(messages: cmd_result.messages)
  end

  def extract_query(text)
     text.gsub(/\A(adicionar?|add)\s*/i, "").strip
  end

  def help_message
    <<~MSG.strip
      🎲 *BG Price Tracker — Comandos disponíveis*
      📥 *adicionar [jogo]* — adiciona um jogo à sua coleção
      📊 *monitorar [jogo]* — monitora o preço de um jogo
      🗑️ *deletar [jogo]* — remove um jogo da sua coleção

      ❓ *ajuda* — exibe esta mensagem
    MSG
  end

  def fallback_message
    "Não entendi. Envie ❓ *ajuda* para ver os comandos disponíveis. 🤔"
  end
end
