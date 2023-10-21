import { useLoaderData } from 'react-router-dom'
import {
  Box,
} from '@chakra-ui/react'

type Project = {
  name: string,
  status: string,
  path: string,
}

export async function loader() {
  // TODO: fetch projects from API
  const projects: Project[] = [
    { name: 'A', status: 'running', path: '/repos/a' },
    { name: 'B', status: 'running', path: '/repos/b' },
    { name: 'C', status: 'exited', path: '/repos/b' },
  ]

  return { projects }
}

export default function Projects() {
  const { projects } = useLoaderData() as { projects: Project[] }
  return (
    <Box p={4}>Projects~</Box>
  )
}
