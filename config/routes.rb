Rails.application.routes.draw do
  root 'draw_name#index'

  get 'get_token', to: 'draw_name#get_token'
  get 'band', to: 'draw_name#band'
  get 'logout', to: 'draw_name#logout'

  get 'error', to: 'draw_name#error'

  get 'post', to: 'draw_name#post'
  get 'post_reroll', to: 'draw_name#post_reroll'
  get 'post_add', to: 'draw_name#post_add'
  get 'post_reset', to: 'draw_name#post_reset'
  get 'post_refresh', to: 'draw_name#post_refresh'
end
