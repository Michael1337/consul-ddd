Rails.application.routes.draw do
  mount Ckeditor::Engine => "/ckeditor"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?


  root :to => redirect('/maintenance.html', status: 302)
  get '*path' => redirect('/maintenance.html', status: 302)
end
