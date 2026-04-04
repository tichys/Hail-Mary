import { useBackend } from '../backend';
import { Box, Button, Section, Flex, Divider } from '../components';
import { Window } from '../layouts';

type LobbyMenuData = {
  character_name: string;
  game_state: string;
  is_observer: boolean;
  has_polls: boolean;
  is_interviewee: boolean;
  rules_accepted: boolean;
};

export const LobbyMenu = (props, context) => {
  const { act, data } = useBackend<LobbyMenuData>(context);
  const {
    character_name = 'WANDERER',
    game_state = 'pregame',
    has_polls = false,
    rules_accepted = true,
  } = data;

  const isPregame = game_state === 'pregame';
  const isRunning = game_state === 'running';

  return (
    <Window width={320} height={480} title="ROBCO TERMINAL" theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) WASTELAND TERMINAL
        </Box>

        <Section>
          <Box style={{ fontSize: '18px', fontWeight: 'bold', color: '#4cff4c', textAlign: 'center' }}>
            {character_name}
          </Box>
        </Section>

        <Section title="> MAIN MENU">
          <Button
            fluid
            content="> CHARACTER CREATOR"
            onClick={() => act('show_preferences')}
            style={{ marginBottom: '5px' }}
          />

          {isPregame && (
            <>
              <Box
                style={{
                  color: '#e8a020',
                  padding: '8px 4px',
                  fontSize: '13px',
                }}
              >
                &gt; AWAITING ROUND START...
              </Box>
              <Button
                fluid
                content="> REFRESH"
                onClick={() => act('refresh')}
                style={{ marginTop: '5px' }}
              />
              <Button
                fluid
                content="> FIX CHAT WINDOW"
                onClick={() => act('fix_chat')}
              />
            </>
          )}

          {isRunning && (
            <>
              <Button
                fluid
                content="> JOIN GAME"
                onClick={() => act('late_join')}
                color="good"
                style={{ marginBottom: '5px' }}
              />
              <Button
                fluid
                content="> OBSERVE"
                onClick={() => act('observe')}
                style={{ marginBottom: '5px' }}
              />
              <Button
                fluid
                content="> FIX CHAT WINDOW"
                onClick={() => act('fix_chat')}
              />
            </>
          )}
        </Section>

        <Divider />

        <Section title="> LINKS">
          <Button
            fluid
            content="> WIKI"
            onClick={() => act('view_wiki')}
            style={{ marginBottom: '5px' }}
          />
          <Button
            fluid
            content="> SERVER RULES"
            onClick={() => act('show_rules')}
          />
          {has_polls && (
            <Button
              fluid
              content="> PLAYER POLLS"
              onClick={() => act('show_polls')}
              style={{ marginTop: '5px' }}
            />
          )}
        </Section>

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};
