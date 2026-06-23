require_relative '../server'
require_relative '../lib/go_fish/game'
require_relative '../lib/card'

RSpec.describe Server do
  def create_players_from_sessions(sessions)
    sessions.each_with_index do |session, i|
      session.visit '/'
      name = "Player #{i + 1}"
      session.fill_in :name, with: name
      session.click_on 'Join'
    end
  end

  context 'before game is started' do
    it 'is possible to join a lobby', :js do
      visit '/'
      fill_in :name, with: 'John'
      click_on 'Join'
      expect(page).to have_content('Lobby')
      expect(page).to have_css("meta[name='api_key'][content]", visible: false)
      expect(page).to have_content('John')
    end

    it 'works with other names' do
      visit '/'
      fill_in :name, with: 'Henry'
      click_on 'Join'
      expect(page).to have_content('Lobby')
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
        expect(session).to have_content('Lobby')
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

    context 'when a player has already entered a name' do
      it 'redirects to lobby' do
        visit '/'
        fill_in :name, with: 'John'
        click_on 'Join'

        visit '/'
        expect(page).to have_content('Lobby')
        expect(page).to have_content('John')
      end
    end

    context 'when one player is in the lobby' do
      let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }

      before do
        create_players_from_sessions([session1])
      end

      it 'does not allow player to start the game', :js do
        expect(session1).to have_button('Start', disabled: true)
      end
    end

    context 'when multiple players are in the lobby' do
      let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
      let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
      let!(:session3) { Capybara::Session.new(:rack_test, Server.new) }
      let(:sessions) { [session1, session2, session3] }

      before do
        create_players_from_sessions(sessions)

        # refresh the sessions
        sessions.each do |session|
          session.visit '/'
        end
      end

      it 'shows list of other players' do
        expect(session1).to have_content('Player 2')
        expect(session1).to have_content('Player 3')

        expect(session2).to have_content('Player 1')
        expect(session2).to have_content('Player 3')

        expect(session3).to have_content('Player 1')
        expect(session3).to have_content('Player 3')
      end

      it 'allows any player to press the start button' do
        expect(session1).to have_button('Start', disabled: false)
        expect(session2).to have_button('Start', disabled: false)
        expect(session3).to have_button('Start', disabled: false)
      end
    end
  end

  context 'when a game is started' do
    let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
    let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
    let!(:session3) { Capybara::Session.new(:rack_test, Server.new) }
    let(:sessions) { [session1, session2, session3] }

    before do
      create_players_from_sessions(sessions)

      # refresh the sessions
      sessions.each do |session|
        session.visit '/'
      end

      session1.click_on 'Start'
      sessions.each do |session|
        session.visit '/'
      end
    end

    it 'redirects to game' do
      expect(session1).to have_content('Game')
      expect(session2).to have_content('Game')
      expect(session3).to have_content('Game')
    end

    it 'shows list of other players' do
      expect(session1).to have_content('Player 2')
      expect(session1).to have_content('Player 3')

      expect(session2).to have_content('Player 1')
      expect(session2).to have_content('Player 3')

      expect(session3).to have_content('Player 1')
      expect(session3).to have_content('Player 3')
    end

    it 'shows whose turn it is' do
      expect(session1).to have_content('Your Turn')
      expect(session2).to have_content("Player 1's Turn")
      expect(session3).to have_content("Player 1's Turn")
    end

    it 'has correct player dropdown options' do
      dropdown_options1 = session1.find_field('Player').all('option').map(&:text)
      expect(dropdown_options1).to eq ['Player 2', 'Player 3']

      dropdown_options2 = session2.find_field('Player').all('option').map(&:text)
      expect(dropdown_options2).to eq ['Player 1', 'Player 3']

      dropdown_options3 = session3.find_field('Player').all('option').map(&:text)
      expect(dropdown_options3).to eq ['Player 1', 'Player 2']
    end

    it 'has correct rank dropdown options' do
      game = Server.game
      game.players[0].cards = [Card.new('A', 'Spades'), Card.new('5', 'Hearts')]
      game.players[1].cards = [Card.new('3', 'Spades'), Card.new('6', 'Hearts'), Card.new('8', 'Spades')]
      session1.visit '/'
      session2.visit '/'

      dropdown_options1 = session1.find_field('Rank').all('option').map(&:text)
      expect(dropdown_options1).to eq %w[A 5]

      dropdown_options2 = session2.find_field('Rank').all('option').map(&:text)
      expect(dropdown_options2).to eq %w[3 6 8]
    end

    it 'sorts the ranks' do
    end

    it 'does not duplicate ranks in dropdown' do
    end

    it 'shows how many cards each player has' do
      expect(session1).to have_content("Cards: #{Game::SMALL_GAME_CARDS}")
      expect(session2).to have_content("Cards: #{Game::SMALL_GAME_CARDS}")
      expect(session3).to have_content("Cards: #{Game::SMALL_GAME_CARDS}")
    end

    it 'enables request button only for current player' do
      expect(session1).to have_button('Request', disabled: false)
      expect(session2).to have_button('Request', disabled: true)
      expect(session3).to have_button('Request', disabled: true)
    end
  end
end
