import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Divider } from '../components';
import { Window } from '../layouts';

type JobData = {
  title: string;
  current: number;
  total: number;
  available: boolean;
  locked: boolean;
  lock_reason: string;
};

type FactionData = {
  name: string;
  jobs: JobData[];
};

type LateJoinData = {
  round_duration: string;
  evacuation_status: string;
  factions: FactionData[];
};

export const LateJoin = (props, context) => {
  const { act, data } = useBackend<LateJoinData>(context);
  const {
    round_duration = '',
    evacuation_status = '',
    factions = [],
  } = data;

  const [selectedFaction, setSelectedFaction] = useLocalState(context, 'selFaction', '');

  return (
    <Window width={960} height={720} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>VAULT-TEC CORP</span>
        </Box>

        <Section>
          <Flex justify="center">
            <Flex.Item style={{ color: '#2a7a52', fontSize: '12px' }}>
              Round Duration: {round_duration}
            </Flex.Item>
            {evacuation_status && (
              <Flex.Item style={{ color: '#c8160a', marginLeft: '20px' }}>
                {evacuation_status}
              </Flex.Item>
            )}
          </Flex>
        </Section>

        <Flex wrap>
          {factions.map(faction => (
            <Flex.Item
              key={faction.name}
              basis="25%"
              style={{ padding: '5px' }}
            >
              <Section
                title={`> ${faction.name}`}
                style={{
                  height: '100%',
                  border: selectedFaction === faction.name ? '2px solid #4cff4c' : '1px solid #1a5e38',
                }}
              >
                <Box style={{ maxHeight: '180px', overflowY: 'auto' }}>
                  {faction.jobs.map(job => (
                    <Flex
                      key={job.title}
                      align="center"
                      justify="space-between"
                      style={{
                        padding: '2px 0',
                        borderBottom: '1px solid #0d3322',
                      }}
                    >
                      <Flex.Item
                        grow
                        style={{
                          color: job.locked ? '#2a4a38' : job.available ? '#4cff4c' : '#2a7a52',
                        }}
                      >
                        {job.title}
                      </Flex.Item>
                      <Flex.Item>
                        {job.locked ? (
                          <Button
                            compact
                            content="LOCKED"
                            color="bad"
                            tooltip={job.lock_reason}
                          />
                        ) : job.available ? (
                          <Button
                            compact
                            content={`JOIN (${job.current}/${job.total === -1 ? '∞' : job.total})`}
                            onClick={() => act('join_job', { job: job.title })}
                          />
                        ) : (
                          <Button
                            compact
                            content="FULL"
                            disabled
                          />
                        )}
                      </Flex.Item>
                    </Flex>
                  ))}
                </Box>
              </Section>
            </Flex.Item>
          ))}
        </Flex>

        <Divider />

        <Box className="CharacterSetup__footer">
          JOIN GAME | SELECT OCCUPATION
        </Box>
      </Window.Content>
    </Window>
  );
};
