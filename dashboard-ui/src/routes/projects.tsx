import { useLoaderData } from 'react-router-dom'
import {
  Box,
  Table,
  TableContainer,
  Tbody,
  Thead,
  Th,
  Tr,
  Td,
  Heading,
  Button,
} from '@chakra-ui/react'
import { CheckCircleIcon, QuestionIcon, WarningIcon } from '@chakra-ui/icons'

type Project = {
  name: string,
  status: string,
  path?: string,
}

export async function loader() {
  // TODO: fetch projects from API
  const projects: Project[] = [
    { name: 'A', status: 'running', path: '/repos/a' },
    { name: 'B', status: 'running', path: '/repos/b' },
    { name: 'C', status: 'exited', path: '/repos/c' },
    { name: 'D', status: 'unknown', path: undefined },
  ]

  return { projects }
}

function iconFor(status: string) {
  if (status == 'running') {
    return <CheckCircleIcon color='green.500' />
  } else if (status == 'exited') {
    return <WarningIcon color='blue.500' />
  } else {
    return <QuestionIcon color='gray.500' />
  }
}

function actionBtnFor(project: Project) {
  if (project.status == 'running') {
    return (
      <>
        <Button colorScheme='red' size='xs' mr='4px' onClick={stopProject} value={project.name}>Stop</Button>
        <Button colorScheme='orange' size='xs' onClick={restartProject} value={project.name}>Restart</Button>
      </>
    )
  } else if (project.status == 'exited') {
    return <Button colorScheme='blue' size='xs' onClick={startProject} value={project.name}>Start</Button>
  } else {
    return null
  }
}

function startProject(event: React.MouseEvent<HTMLButtonElement, MouseEvent>) {
  console.log(event.currentTarget.value)
}

function stopProject(event: React.MouseEvent<HTMLButtonElement, MouseEvent>) {
  console.log(event.currentTarget.value)
}

function restartProject(event: React.MouseEvent<HTMLButtonElement, MouseEvent>) {
  console.log(event.currentTarget.value)
}

export default function Projects() {
  const { projects } = useLoaderData() as { projects: Project[] }

  return (
    <>
      <Box p={4}>
        <Heading as='h2'>Projects</Heading>
      </Box>
      <TableContainer p={4}>
        <Table variant='simple'>
          <Thead>
            <Tr>
              <Th width="60px"></Th>
              <Th>Name</Th>
              <Th>status</Th>
              <Th>Path</Th>
              <Th></Th>
            </Tr>
          </Thead>
          <Tbody>
            {projects.map(project => (
              <Tr key={project.name}>
                <Td>{iconFor(project.status)}</Td>
                <Td>{project.name}</Td>
                <Td>{project.status}</Td>
                <Td>{project.path ?? 'Not registered'}</Td>
                <Td>
                  {actionBtnFor(project)}
                </Td>
              </Tr>
            ))}
          </Tbody>
        </Table>
      </TableContainer>
    </>
  )
}
