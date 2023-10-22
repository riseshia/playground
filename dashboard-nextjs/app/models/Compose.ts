import { execSync } from 'child_process'

const baseBranch = 'master'

const update = async () => {
  execSync(`git checkout ${baseBranch}`)
  execSync(`git pull origin ${baseBranch}`)
  execSync(`docker compose restart`)
}

const isOutdated = async () => {
  const local = execSync(`git rev-parse ${baseBranch}`).toString().trim()
  const remote = execSync(`git rev-parse origin/${baseBranch}`).toString().trim()

  return (local !== remote)
}

export const Compose = {
  isOutdated,
  update,
}
