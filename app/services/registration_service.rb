class RegistrationService
  CONSENT_YES = /\A(sim|s|yes|aceito|concordo)\z/i
  CONSENT_NO  = /\A(n(?:ao|ão)|nao|n|no|recuso|rejeito)\z/i

  Result = Struct.new(:messages, keyword_init: true)

  def initialize(phone:, text:, profile_name: nil, user: nil)
    @phone = phone
    @text  = text.to_s.strip
    @profile_name = profile_name.to_s.strip
    @user  = user
  end

  def call
    @user.nil? ? register_new_user : process_consent
  end

  private

  def register_new_user
    @user = User.create!(phone: @phone, consent_status: "pending")
    Result.new(messages: [welcome_message])
  rescue ActiveRecord::RecordNotUnique
    @user = User.find_by!(phone: @phone)
    process_consent
  end

  def process_consent
    if @text.match?(CONSENT_YES)
      @user.update!(consent_status: "accepted", consent_at: Time.current)
      Result.new(messages: [accepted_message])
    elsif @text.match?(CONSENT_NO)
      @user.update!(consent_status: "rejected")
      Result.new(messages: [rejected_message])
    else
      Result.new(messages: [consent_prompt])
    end
  end

  def welcome_message
    dice = "\xF0\x9F\x8E\xB2"
    lock = "\xF0\x9F\x94\x92"
    <<~MSG.strip
      Ol\u00e1! #{@profile_name} Bem-vindo ao *BG Price Tracker* #{dice}

      Monitoro pre\u00e7os de jogos de tabuleiro e te aviso quando o pre\u00e7o cair!

      #{lock} Para continuar, preciso da sua autoriza\u00e7\u00e3o para armazenar seu n\u00famero de telefone.

      #{consent_prompt}
    MSG
  end

  def consent_prompt
    "Voc\u00ea autoriza? Responda *SIM* para aceitar ou *N\u00c3O* para recusar."
  end

  def accepted_message
    check = "\xE2\x9C\x85"
    megaphone = "\xF0\x9F\x94\x94"
    <<~MSG.strip
      #{check} Tudo certo! Voc\u00ea est\u00e1 cadastrado.

      Agora voc\u00ea pode adicionar jogos \u00e0 sua cole\u00e7\u00e3o e receber alertas de pre\u00e7o. #{megaphone}

      Envie *ajuda* para ver os comandos dispon\u00edveis.
    MSG
  end

  def rejected_message
    wave = "\xF0\x9F\x91\x8B"
    "Tudo bem! #{@profile_name} Seu n\u00famero n\u00e3o ser\u00e1 armazenado. Se mudar de ideia, \u00e9 s\u00f3 nos enviar uma mensagem. #{wave}"
  end
end
