import { execSync } from 'child_process'
import { copyFileSync, existsSync, readFileSync, writeFileSync } from 'fs'

import { Project } from '../../types/common'

const projectsDBPath = 'db/projects.json'
const defaultProjectsDBPath = 'projects-default.json'

function fetchFromDB() {
  if (!existsSync(projectsDBPath)) {
    copyFileSync(defaultProjectsDBPath, projectsDBPath)
  }

  const data = readFileSync(projectsDBPath, 'utf8')

  return JSON.parse(data).map((project: any) => {
    return {
      name: project.name,
      status: 'exited',
      configPath: project.configPath,
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

const syncDB = async (projects: Project[]) => {
  writeFileSync(projectsDBPath, JSON.stringify(projects))
}

const all = async () => {
  const fromDB = fetchFromDB()
  const fromDocker = fetchFromDocker()

  const allProjects = mergeProjects(fromDB, fromDocker)
  const sorted = allProjects.sort((a, b) => { return a.name.localeCompare(b.name) })

  await syncDB(sorted)

  return sorted
}

const findByName = async (name: string) => {
  const projects = await all()

  return projects.find((project: Project) => {
    return project.name === name
  })
}

const deleteByName = async (name: string) => {
  const projects = await all()

  const updatedList = projects.filter((project) => { return project.name !== name })

  if (updatedList.length === projects.length) {
    throw new Error(`project '${name}' not found`)
  } else {
    await syncDB(updatedList)
  }
}

const start = async (project: Project) => {
  execSync(`docker compose -f ${project.configPath} up -d`)
}

const stop = async (project: Project) => {
  execSync(`docker compose -f ${project.configPath} down --remove-orphans`)
}

const restart = async (project: Project) => {
  execSync(`docker compose -f ${project.configPath} restart`)
}

export const Projects = {
  all,
  findByName,
  deleteByName,
  start,
  stop,
  restart,
}
