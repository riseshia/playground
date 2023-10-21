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
  useToast,
  UseToastOptions,
} from '@chakra-ui/react'
import { CheckCircleIcon, DeleteIcon, QuestionIcon, WarningIcon } from '@chakra-ui/icons'
import { useEffect, useState } from 'react'
import React from 'react'

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

function startProject(projectName: string) {
  return fetch('/api/projects/start', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: projectName })
  })
}

function stopProject(projectName: string) {
  return fetch('/api/projects/stop', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: projectName })
  })
}

function restartProject(projectName: string) {
  return fetch('/api/projects/restart', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: projectName })
  })
}

function deleteProject(projectName: string) {
  return fetch('/api/projects', {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: projectName })
  })
}

export default function Projects() {
  const [projects, setProjects] = useState<Project[]>([])
  const toast = useToast()

  useEffect(() => {
    fetchProjects().then(projects => setProjects(projects))
  }, [])

  const handleClickStart = (event: React.MouseEvent<HTMLButtonElement, MouseEvent>) => {
    const projectName = event.currentTarget.value
      startProject(projectName)
        .then((res) => res.json())
        .then((json) => {
          let toastConfig: UseToastOptions;
          if (json.error) {
            toastConfig = {
              title: 'Project start signal failed',
              description: `Project ${projectName} failed to start: ${json.error}`,
              status: 'error',
              duration: 3000,
              isClosable: true,
            }
          } else {
            toastConfig = {
              title: 'Project start signal sent',
              description: `Project ${projectName} is starting`,
              status: 'success',
              duration: 3000,
              isClosable: true,
            }
          }
          toast(toastConfig)
        })
        .then(() => fetchProjects())
        .then(projects => setProjects(projects))
  }

  const handleClickRestart = (event: React.MouseEvent<HTMLButtonElement, MouseEvent>) => {
    const projectName = event.currentTarget.value
      restartProject(projectName)
        .then((res) => res.json())
        .then((json) => {
          let toastConfig: UseToastOptions;
          if (json.error) {
            toastConfig = {
              title: 'Project restart signal failed',
              description: `Project ${projectName} failed to restart: ${json.error}`,
              status: 'error',
              duration: 3000,
              isClosable: true,
            }
          } else {
            toastConfig = {
              title: 'Project restart signal sent',
              description: `Project ${projectName} is restarting`,
              status: 'success',
              duration: 3000,
              isClosable: true,
            }
          }
          toast(toastConfig)
        })
        .then(() => fetchProjects())
        .then(projects => setProjects(projects))
  }

  const handleClickStop = (event: React.MouseEvent<HTMLButtonElement, MouseEvent>) => {
    const projectName = event.currentTarget.value
      stopProject(projectName)
        .then((res) => res.json())
        .then((json) => {
          let toastConfig: UseToastOptions;
          if (json.error) {
            toastConfig = {
              title: 'Project stop signal failed',
              description: `Project ${projectName} failed to stop: ${json.error}`,
              status: 'error',
              duration: 3000,
              isClosable: true,
            }
          } else {
            toastConfig = {
              title: 'Project stop signal sent',
              description: `Project ${projectName} is stopping`,
              status: 'success',
              duration: 3000,
              isClosable: true,
            }
          }
          toast(toastConfig)
        })
        .then(() => fetchProjects())
        .then(projects => setProjects(projects))
  }

  const handleClickDelete = (event: React.MouseEvent<HTMLButtonElement, MouseEvent>) => {
    if (!confirm("Are you sure to delete this project?")) {
      return
    }

    const projectName = event.currentTarget.value
      deleteProject(projectName)
        .then((res) => res.json())
        .then((json) => {
          let toastConfig: UseToastOptions;
          if (json.error) {
            toastConfig = {
              title: 'Project deletion failed',
              description: `Error: ${json.error}`,
              status: 'error',
              duration: 3000,
              isClosable: true,
            }
          } else {
            toastConfig = {
              title: 'Project deleted',
              description: `Project ${projectName} is deleted`,
              status: 'success',
              duration: 3000,
              isClosable: true,
            }
          }
          toast(toastConfig)
        })
        .then(() => fetchProjects())
        .then(projects => setProjects(projects))
  }

  const actionBtnFor = (project: Project) => {
    if (project.status == 'running') {
      return (
        <>
          <Button colorScheme='red' size='xs' mr='4px' onClick={handleClickStop} value={project.name}>Stop</Button>
          <Button colorScheme='orange' size='xs' onClick={handleClickRestart} value={project.name}>Restart</Button>
        </>
      )
    } else if (project.status == 'exited') {
      return <Button colorScheme='blue' size='xs' onClick={handleClickStart} value={project.name}>Start</Button>
    } else {
      return null
    }
  }

  return (
    <>
      <Box p={4}>
        <Heading as='h1' size='md'>Compose Projects</Heading>
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
                <Td>
                  {project.name}
                  <Button colorScheme='red' size='xs' ml='8px' onClick={handleClickDelete} value={project.name}>
                    <DeleteIcon />
                  </Button>
                </Td>
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
