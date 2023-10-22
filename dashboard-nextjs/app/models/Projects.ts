import { execSync } from 'child_process'
import { readFileSync } from 'fs'

import { Project } from '../../types/common'

function fetchFromDB() {
  const data = readFileSync('db/projects.json', 'utf8')

  return JSON.parse(data).map((project: any) => {
    return {
      name: project.name,
      status: 'exited',
      configPath: project.path,
    }
  })
}

function fetchFromDocker() {
  const stdout = execSync('docker compose ls --all --format=json').toString()

  return JSON.parse(stdout).map((project: any) => {
    return {
      name: project.Name,
      status: project.Status.split('(')[0],
      configPath: project.ConfigFiles,
    }
  })
}

interface ProjectByKey {
  [key: string]: Project
}

function mergeProjects(base: Project[], override: Project[]) {
  const prjByKey: ProjectByKey = {}
  override.forEach((project) => prjByKey[project.name] = project)

  let projects: Project[] = []
  base.forEach((project) => {
    if (!prjByKey[project.name]) {
      projects.push(project)
    }
  })
  override.forEach((project) => { projects.push(project) })

  return projects
}

const all = async () => {
  const fromDB = fetchFromDB()
  const fromDocker = fetchFromDocker()

  const allProjects = mergeProjects(fromDB, fromDocker)

  return allProjects.sort((a, b) => { return a.name.localeCompare(b.name) })
}

export const Projects = {
  all,
}
