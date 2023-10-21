'use client'

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
import { useEffect, useState } from 'react'

type Project = {
  name: string,
  status: string,
  path?: string,
}

type ProjectsResponse = {
  data: {
    projects: Project[],
  },
}

async function fetchProjects(): Promise<Project[]> {
  const res = await fetch('/api/projects')
  const json = await res.json() as ProjectsResponse
  return json.data.projects
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
  const [projects, setProjects] = useState<Project[]>([])

  useEffect(() => {
    fetchProjects().then(projects => setProjects(projects))
  }, [])

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
