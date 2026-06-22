require_relative '../server'

RSpec.describe Server do
  it 'is possible to join a game', :js do
    visit '/'
    fill_in :name, with: 'John'
    click_on 'Join'
    expect(page).to have_content('Players')
    expect(page).to have_content('John')
  end

  it 'works with other names' do
    visit '/'
    fill_in :name, with: 'Henry'
    click_on 'Join'
    expect(page).to have_content('Players')
    expect(page).to have_content('Henry')
  end

  it 'allows multiple players to join' do
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)
    [session1, session2].each_with_index do |session, i|
      session.visit '/'
      session.fill_in :name, with: "Player #{i + 1}"
      session.click_on 'Join'
      expect(session).to have_content('Players')
    end
  end
end
