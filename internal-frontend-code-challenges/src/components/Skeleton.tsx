import './Skeleton.css'

export function Skeleton() {
  return (
    <div className='loading-overlay'>
      <article aria-busy='true'></article>
    </div>
  )
}
