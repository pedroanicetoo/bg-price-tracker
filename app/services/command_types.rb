module CommandTypes
  ADD_PATTERN = /\A(adicionar?|add)\s+.+/i # adicionar [item]
  TRACK_PATTERN = /\A(monitorar?|track)\s+.+/i # monitorar [item]
  DELETE_PATTERN = /\A(deletar?|delete)\s+.+/i # deletar [item]
  HELP_PATTERN = /\A(ajuda|help|comandos|\?)\z/i # ajuda
end
