require_relative '../server'

RSpec.describe Server do
  it 'is possible to join a game', :js do
    visit '/'
    fill_in :name, with: 'John'
    click_on 'Join'
    expect(page).to have_content('Players')
    expect(page).to have_css("meta[name='api_key'][content]", visible: false)
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
      name = "Player #{i + 1}"
      session.fill_in :name, with: name
      session.click_on 'Join'
      expect(session).to have_content('Players')
      expect(session).to have_content(name)
    end
  end

  it 'gives players of the same name different api keys' do
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)
    api_keys = []
    [session1, session2].each do |session|
      session.visit '/'
      session.fill_in :name, with: 'John'
      session.click_on 'Join'
      sleep(1) # Pauses the test for 1 second

      meta_tag = session.find("meta[name='api_key']", visible: false)
      api_key = meta_tag[:content]

      api_keys.push(api_key)
    end

    expect(api_keys[0]).not_to eq api_keys[1]
  end

  context 'when a player has already joined' do
    it 'redirects to game' do
      visit '/'
      fill_in :name, with: 'John'
      click_on 'Join'

      visit '/'
      expect(page).to have_content('Players')
      expect(page).to have_content('John')
    end
  end
end
